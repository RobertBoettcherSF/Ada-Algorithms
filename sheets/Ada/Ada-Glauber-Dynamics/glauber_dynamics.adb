--  Glauber_Dynamics body — 2-D Ising heat-bath / Metropolis MCMC.

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Glauber_Dynamics
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
      --  Map [0,1) → 1 .. L without hitting L+1.
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

   function Clamp01 (X : Real) return Unit_Interval is
   begin
      if X <= 0.0 then
         return 0.0;
      elsif X >= 1.0 then
         return 1.0;
      else
         return X;
      end if;
   end Clamp01;

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
      --  Ada "mod" for negative dividends yields non-negative remainder.
      if R < 1 then
         R := R + Integer (L);
      end if;
      return Coord (R);
   end Wrap;

   function Neighbor_Sum (Lat : Lattice; X, Y : Coord) return Real is
      L : constant Lattice_Size := Lat.L;
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
      --  Flipping σ → −σ changes interaction energy by
      --  ΔE = 2 σ_i (J ∑_nn σ_j + h).
      Sig : constant Real := Real (Lat.Spins (X, Y));
   begin
      return 2.0 * Sig * Local_Field (Lat, X, Y, Cfg);
   end Delta_E_Flip;

   ---------------------------------------------------------------------------
   -- Acceptance probabilities
   ---------------------------------------------------------------------------

   function Heatbath_Prob_Plus
     (Local_H : Real; Beta : Real) return Unit_Interval
   is
      --  P(+1) = 1 / (1 + exp(−2 β h_i)).  Numerically stable form.
      Arg : constant Real := -2.0 * Beta * Local_H;
      P   : Real;
   begin
      if Arg > 80.0 then
         --  exp(Arg) huge → P ≈ 0
         return 0.0;
      elsif Arg < -80.0 then
         --  exp(Arg) ≈ 0 → P ≈ 1
         return 1.0;
      else
         P := 1.0 / (1.0 + EF.Exp (Arg));
         return Clamp01 (P);
      end if;
   end Heatbath_Prob_Plus;

   function Heatbath_Flip_Prob
     (Lat : Lattice; X, Y : Coord; Cfg : Config) return Unit_Interval
   is
      --  Wikipedia Fermi function: p(ΔE) = 1/(1+e^{β ΔE}).
      DE  : constant Real := Delta_E_Flip (Lat, X, Y, Cfg);
      Arg : constant Real := Cfg.Beta * DE;
      P   : Real;
   begin
      if Arg > 80.0 then
         return 0.0;
      elsif Arg < -80.0 then
         return 1.0;
      else
         P := 1.0 / (1.0 + EF.Exp (Arg));
         return Clamp01 (P);
      end if;
   end Heatbath_Flip_Prob;

   function Metropolis_Accept_Prob
     (Delta_E : Real; Beta : Real) return Unit_Interval
   is
      Arg : Real;
   begin
      if Delta_E <= 0.0 then
         return 1.0;
      end if;
      Arg := -Beta * Delta_E;
      if Arg < -80.0 then
         return 0.0;
      else
         return Clamp01 (EF.Exp (Arg));
      end if;
   end Metropolis_Accept_Prob;

   ---------------------------------------------------------------------------
   -- Single-site updates / sweeps
   ---------------------------------------------------------------------------

   procedure Glauber_Update_Site
     (Lat   : in out Lattice;
      X, Y  : Coord;
      Cfg   : Config;
      State : in out RNG_State)
   is
      Hi : constant Real := Local_Field (Lat, X, Y, Cfg);
      P  : constant Unit_Interval := Heatbath_Prob_Plus (Hi, Cfg.Beta);
   begin
      if Next_Unit (State) < P then
         Lat.Spins (X, Y) := 1;
      else
         Lat.Spins (X, Y) := -1;
      end if;
   end Glauber_Update_Site;

   procedure Metropolis_Update_Site
     (Lat   : in out Lattice;
      X, Y  : Coord;
      Cfg   : Config;
      State : in out RNG_State)
   is
      DE : constant Real := Delta_E_Flip (Lat, X, Y, Cfg);
      P  : constant Unit_Interval :=
        Metropolis_Accept_Prob (DE, Cfg.Beta);
   begin
      if Next_Unit (State) < P then
         Lat.Spins (X, Y) := Spin (-Integer (Lat.Spins (X, Y)));
      end if;
   end Metropolis_Update_Site;

   procedure Sweep_Sites
     (Lat       : in out Lattice;
      Cfg       : Config;
      State     : in out RNG_State;
      Order     : Sweep_Order;
      Use_Metro : Boolean)
   is
      L : constant Lattice_Size := Lat.L;
      N : constant Positive := Site_Count (Lat);
      X, Y : Coord;
      Parity : Integer;
   begin
      case Order is
         when Random_Sites =>
            for K in 1 .. N loop
               X := Next_Index (State, L);
               Y := Next_Index (State, L);
               if Use_Metro then
                  Metropolis_Update_Site (Lat, X, Y, Cfg, State);
               else
                  Glauber_Update_Site (Lat, X, Y, Cfg, State);
               end if;
            end loop;

         when Sequential =>
            for Xi in 1 .. L loop
               for Yi in 1 .. L loop
                  if Use_Metro then
                     Metropolis_Update_Site (Lat, Xi, Yi, Cfg, State);
                  else
                     Glauber_Update_Site (Lat, Xi, Yi, Cfg, State);
                  end if;
               end loop;
            end loop;

         when Checkerboard =>
            --  Two sublattice passes (even then odd parity of X+Y).
            for Pass in 0 .. 1 loop
               for Xi in 1 .. L loop
                  for Yi in 1 .. L loop
                     Parity := (Integer (Xi) + Integer (Yi)) mod 2;
                     if Parity = Pass then
                        if Use_Metro then
                           Metropolis_Update_Site
                             (Lat, Xi, Yi, Cfg, State);
                        else
                           Glauber_Update_Site
                             (Lat, Xi, Yi, Cfg, State);
                        end if;
                     end if;
                  end loop;
               end loop;
            end loop;
      end case;
   end Sweep_Sites;

   procedure Glauber_Sweep
     (Lat   : in out Lattice;
      Cfg   : Config;
      State : in out RNG_State;
      Order : Sweep_Order := Random_Sites)
   is
   begin
      Sweep_Sites (Lat, Cfg, State, Order, Use_Metro => False);
   end Glauber_Sweep;

   procedure Metropolis_Sweep
     (Lat   : in out Lattice;
      Cfg   : Config;
      State : in out RNG_State;
      Order : Sweep_Order := Random_Sites)
   is
   begin
      Sweep_Sites (Lat, Cfg, State, Order, Use_Metro => True);
   end Metropolis_Sweep;

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
      --  Count each nearest-neighbor bond once (right + down) with PBC.
      Bond : Real := 0.0;
      Field : Real := 0.0;
      L : constant Lattice_Size := Lat.L;
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

   function Susceptibility_Estimator
     (Mean_M, Mean_M2 : Real; Beta : Real; N : Positive) return Real
   is
      Var : constant Real := Mean_M2 - Mean_M * Mean_M;
   begin
      if Var < 0.0 then
         return 0.0;
      end if;
      return Beta * Real (N) * Var;
   end Susceptibility_Estimator;

   ---------------------------------------------------------------------------
   -- Exact 2×2 enumeration (16 configs)
   ---------------------------------------------------------------------------

   --  Build a temporary 2×2 lattice from a 4-bit mask (bit 0 = site 1,1 …
   --  bit 3 = site 2,2).  Bit set ⇒ +1, clear ⇒ −1.
   procedure Fill_2x2_From_Mask (Lat : in out Lattice; Mask : Natural) is
      Bit : Natural;
      S   : Spin;
   begin
      Init_All (Lat, 2, 1);
      for X in 1 .. 2 loop
         for Y in 1 .. 2 loop
            Bit := (X - 1) * 2 + (Y - 1);
            if (Mask / (2 ** Bit)) mod 2 = 1 then
               S := 1;
            else
               S := -1;
            end if;
            Lat.Spins (X, Y) := S;
         end loop;
      end loop;
   end Fill_2x2_From_Mask;

   function Exact_2x2_Partition (Cfg : Config) return Positive_Real is
      Lat : Lattice;
      Z   : Real := 0.0;
      W   : Real;
   begin
      for Mask in 0 .. 15 loop
         Fill_2x2_From_Mask (Lat, Mask);
         W := EF.Exp (-Cfg.Beta * Energy (Lat, Cfg));
         Z := Z + W;
      end loop;
      if Z <= 0.0 then
         raise Invalid_Argument with "Exact_2x2_Partition: Z <= 0";
      end if;
      return Z;
   end Exact_2x2_Partition;

   function Exact_2x2_Mean_Magnetization (Cfg : Config) return Real is
      Lat : Lattice;
      Z, Acc : Real := 0.0;
      W : Real;
   begin
      for Mask in 0 .. 15 loop
         Fill_2x2_From_Mask (Lat, Mask);
         W := EF.Exp (-Cfg.Beta * Energy (Lat, Cfg));
         Z := Z + W;
         Acc := Acc + Magnetization (Lat) * W;
      end loop;
      if Z <= 0.0 then
         raise Invalid_Argument with "Exact_2x2_Mean_Magnetization: Z <= 0";
      end if;
      return Acc / Z;
   end Exact_2x2_Mean_Magnetization;

   function Exact_2x2_Mean_Abs_Magnetization
     (Cfg : Config) return Non_Negative
   is
      Lat : Lattice;
      Z, Acc : Real := 0.0;
      W : Real;
   begin
      for Mask in 0 .. 15 loop
         Fill_2x2_From_Mask (Lat, Mask);
         W := EF.Exp (-Cfg.Beta * Energy (Lat, Cfg));
         Z := Z + W;
         Acc := Acc + Absolute_Magnetization (Lat) * W;
      end loop;
      if Z <= 0.0 then
         raise Invalid_Argument
           with "Exact_2x2_Mean_Abs_Magnetization: Z <= 0";
      end if;
      return Acc / Z;
   end Exact_2x2_Mean_Abs_Magnetization;

   function Exact_2x2_Mean_Energy (Cfg : Config) return Real is
      Lat : Lattice;
      Z, Acc : Real := 0.0;
      W, E : Real;
   begin
      for Mask in 0 .. 15 loop
         Fill_2x2_From_Mask (Lat, Mask);
         E := Energy (Lat, Cfg);
         W := EF.Exp (-Cfg.Beta * E);
         Z := Z + W;
         Acc := Acc + E * W;
      end loop;
      if Z <= 0.0 then
         raise Invalid_Argument with "Exact_2x2_Mean_Energy: Z <= 0";
      end if;
      return Acc / Z;
   end Exact_2x2_Mean_Energy;

end Glauber_Dynamics;
