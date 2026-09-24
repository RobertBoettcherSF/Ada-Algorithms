--  Demon_Method body — 2-D Ising Creutz demon (microcanonical MCMC).

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Demon_Method
  with SPARK_Mode => Off
is

   package EF is new Ada.Numerics.Generic_Elementary_Functions (Real);

   ---------------------------------------------------------------------------
   -- RNG (Numerical Recipes–style LCG, period 2^32)
   ---------------------------------------------------------------------------

   Multiplier : constant RNG_State := 1_664_525;
   Increment  : constant RNG_State := 1_013_904_223;

   procedure Seed_RNG (State : out RNG_State; Seed : Natural) is
   begin
      if Seed = 0 then
         State := 1;
      else
         State := RNG_State (Seed);
      end if;
   end Seed_RNG;

   function Next_Unit (State : in out RNG_State) return Unit_Interval is
      Denom : constant Real := Real (RNG_State'Last) + 1.0;
   begin
      State := State * Multiplier + Increment;
      return Unit_Interval (Real (State) / Denom);
   end Next_Unit;

   function Next_Index
     (State : in out RNG_State; L : Lattice_Size) return Coord
   is
      U : constant Unit_Interval := Next_Unit (State);
      K : Integer := Integer (Real'Floor (U * Real (L))) + 1;
   begin
      if K < 1 then
         K := 1;
      elsif K > Integer (L) then
         K := Integer (L);
      end if;
      return Coord (K);
   end Next_Index;

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   ---------------------------------------------------------------------------
   -- Lattice init / accessors
   ---------------------------------------------------------------------------

   procedure Init_All (Lat : in out Lattice; L : Lattice_Size; Value : Spin) is
   begin
      Lat.L := L;
      for X in 1 .. L loop
         for Y in 1 .. L loop
            Lat.Spins (X, Y) := Value;
         end loop;
      end loop;
   end Init_All;

   procedure Init_Random
     (Lat   : in out Lattice;
      L     : Lattice_Size;
      State : in out RNG_State)
   is
   begin
      Lat.L := L;
      for X in 1 .. L loop
         for Y in 1 .. L loop
            if Next_Unit (State) < 0.5 then
               Lat.Spins (X, Y) := -1;
            else
               Lat.Spins (X, Y) := 1;
            end if;
         end loop;
      end loop;
   end Init_Random;

   function Site_Count (Lat : Lattice) return Positive is
   begin
      return Positive (Lat.L) * Positive (Lat.L);
   end Site_Count;

   function Bond_Count (Lat : Lattice) return Positive is
   begin
      return 2 * Site_Count (Lat);
   end Bond_Count;

   function Get_Spin (Lat : Lattice; X, Y : Coord) return Spin is
   begin
      return Lat.Spins (X, Y);
   end Get_Spin;

   procedure Set_Spin (Lat : in out Lattice; X, Y : Coord; S : Spin) is
   begin
      Lat.Spins (X, Y) := S;
   end Set_Spin;

   ---------------------------------------------------------------------------
   -- Neighbors / local field
   ---------------------------------------------------------------------------

   function Wrap (I : Integer; L : Lattice_Size) return Coord is
      R : Integer := ((I - 1) mod Integer (L)) + 1;
   begin
      if R < 1 then
         R := R + Integer (L);
      end if;
      return Coord (R);
   end Wrap;

   function Neighbor_Sum (Lat : Lattice; X, Y : Coord) return Real is
      L  : constant Lattice_Size := Lat.L;
      Xp : constant Coord := Wrap (Integer (X) + 1, L);
      Xm : constant Coord := Wrap (Integer (X) - 1, L);
      Yp : constant Coord := Wrap (Integer (Y) + 1, L);
      Ym : constant Coord := Wrap (Integer (Y) - 1, L);
      S  : Real := 0.0;
   begin
      S := S + Real (Lat.Spins (Xp, Y));
      S := S + Real (Lat.Spins (Xm, Y));
      S := S + Real (Lat.Spins (X, Yp));
      S := S + Real (Lat.Spins (X, Ym));
      return S;
   end Neighbor_Sum;

   function Local_Field
     (Lat : Lattice; X, Y : Coord; Cfg : Config) return Real
   is
   begin
      return Cfg.J * Neighbor_Sum (Lat, X, Y) + Cfg.H;
   end Local_Field;

   function Delta_E_Flip
     (Lat : Lattice; X, Y : Coord; Cfg : Config) return Real
   is
      Sig : constant Real := Real (Lat.Spins (X, Y));
   begin
      return 2.0 * Sig * Local_Field (Lat, X, Y, Cfg);
   end Delta_E_Flip;

   ---------------------------------------------------------------------------
   -- Creutz demon accept / update
   ---------------------------------------------------------------------------

   function Would_Accept
     (Demon_E : Non_Negative; Delta_E : Real) return Boolean
   is
   begin
      if Delta_E <= 0.0 then
         return True;
      else
         return Demon_E >= Delta_E;
      end if;
   end Would_Accept;

   function New_Demon_Energy
     (Demon_E : Non_Negative; Delta_E : Real) return Non_Negative
   is
      --  E_d' = E_d − ΔE.  When ΔE ≤ 0 this increases the demon;
      --  when ΔE > 0 and accepted, Demon_E ≥ ΔE so result ≥ 0.
      Result : constant Real := Demon_E - Delta_E;
   begin
      if Result < 0.0 then
         --  Should be unreachable under the Pre; clamp for safety.
         return 0.0;
      else
         return Result;
      end if;
   end New_Demon_Energy;

   procedure Demon_Update_Site
     (Lat      : in out Lattice;
      X, Y     : Coord;
      Cfg      : Config;
      Dem      : in out Demon_State;
      Accepted : out Boolean)
   is
      DE : constant Real := Delta_E_Flip (Lat, X, Y, Cfg);
   begin
      if Would_Accept (Dem.Energy, DE) then
         Lat.Spins (X, Y) := Spin (-Integer (Lat.Spins (X, Y)));
         Dem.Energy := New_Demon_Energy (Dem.Energy, DE);
         Accepted := True;
      else
         Accepted := False;
      end if;
   end Demon_Update_Site;

   procedure Demon_Sweep
     (Lat   : in out Lattice;
      Cfg   : Config;
      Dem   : in out Demon_State;
      State : in out RNG_State;
      Order : Sweep_Order := Random_Sites)
   is
      L        : constant Lattice_Size := Lat.L;
      N        : constant Positive := Site_Count (Lat);
      X, Y     : Coord;
      Accepted : Boolean;
   begin
      case Order is
         when Random_Sites =>
            for K in 1 .. N loop
               X := Next_Index (State, L);
               Y := Next_Index (State, L);
               Demon_Update_Site (Lat, X, Y, Cfg, Dem, Accepted);
            end loop;

         when Sequential =>
            for Xi in 1 .. L loop
               for Yi in 1 .. L loop
                  Demon_Update_Site (Lat, Xi, Yi, Cfg, Dem, Accepted);
               end loop;
            end loop;
      end case;
   end Demon_Sweep;

   ---------------------------------------------------------------------------
   -- Observables
   ---------------------------------------------------------------------------

   function Magnetization (Lat : Lattice) return Real is
      Sum : Real := 0.0;
      N   : constant Real := Real (Site_Count (Lat));
   begin
      for X in 1 .. Lat.L loop
         for Y in 1 .. Lat.L loop
            Sum := Sum + Real (Lat.Spins (X, Y));
         end loop;
      end loop;
      return Sum / N;
   end Magnetization;

   function Absolute_Magnetization (Lat : Lattice) return Non_Negative is
      M : constant Real := Magnetization (Lat);
   begin
      if M < 0.0 then
         return -M;
      else
         return M;
      end if;
   end Absolute_Magnetization;

   function Energy (Lat : Lattice; Cfg : Config) return Real is
      Bond  : Real := 0.0;
      Field : Real := 0.0;
      L     : constant Lattice_Size := Lat.L;
      Xp, Yp : Coord;
   begin
      for X in 1 .. L loop
         for Y in 1 .. L loop
            Xp := Wrap (Integer (X) + 1, L);
            Yp := Wrap (Integer (Y) + 1, L);
            Bond := Bond
              + Real (Lat.Spins (X, Y)) * Real (Lat.Spins (Xp, Y));
            Bond := Bond
              + Real (Lat.Spins (X, Y)) * Real (Lat.Spins (X, Yp));
            Field := Field + Real (Lat.Spins (X, Y));
         end loop;
      end loop;
      return -Cfg.J * Bond - Cfg.H * Field;
   end Energy;

   function Energy_Density (Lat : Lattice; Cfg : Config) return Real is
   begin
      return Energy (Lat, Cfg) / Real (Site_Count (Lat));
   end Energy_Density;

   function Total_Energy
     (Lat : Lattice; Cfg : Config; Dem : Demon_State) return Real
   is
   begin
      return Energy (Lat, Cfg) + Dem.Energy;
   end Total_Energy;

   function Temperature_From_Mean_Demon
     (Mean_Demon_Energy : Non_Negative) return Non_Negative
   is
   begin
      return Mean_Demon_Energy;
   end Temperature_From_Mean_Demon;

   function Ising_Demon_Temperature_Estimator
     (Mean_Demon_Energy : Non_Negative; Quantum : Positive_Real := 4.0)
     return Non_Negative
   is
      --  ⟨E_d⟩ = ε / (e^{ε/T} − 1)  ⇒  T = ε / ln(1 + ε/⟨E_d⟩).
      Ratio : Real;
   begin
      if Mean_Demon_Energy <= 0.0 then
         return 0.0;
      end if;
      Ratio := 1.0 + Quantum / Mean_Demon_Energy;
      if Ratio <= 1.0 then
         return 0.0;
      end if;
      return Quantum / EF.Log (Ratio);
   end Ising_Demon_Temperature_Estimator;

end Demon_Method;
