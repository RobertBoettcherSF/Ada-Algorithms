--  Simulated_Annealing body — Metropolis accept, cooling, 1-D & TSP-lite.

pragma Ada_2022;

with Ada.Numerics;
with Ada.Numerics.Generic_Elementary_Functions;

package body Simulated_Annealing
  with SPARK_Mode => Off
is

   package EF is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use EF;

   Two_Pi : constant Real := 2.0 * Real (Ada.Numerics.Pi);

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

   function Next_Gaussian (State : in out RNG_State) return Real is
      U1, U2 : Unit_Interval;
      R      : Real;
   begin
      loop
         U1 := Next_Unit (State);
         exit when U1 > 0.0;
      end loop;
      U2 := Next_Unit (State);
      R  := Sqrt (-2.0 * Log (Real (U1)));
      return R * Cos (Two_Pi * Real (U2));
   end Next_Gaussian;

   function Next_Uniform
     (State : in out RNG_State; Lo, Hi : Real) return Real
   is
      U : constant Unit_Interval := Next_Unit (State);
   begin
      return Lo + Real (U) * (Hi - Lo);
   end Next_Uniform;

   function Next_Natural
     (State : in out RNG_State; Lo, Hi : Natural) return Natural
   is
      U    : constant Unit_Interval := Next_Unit (State);
      Span : constant Natural := Hi - Lo;
      K    : Natural;
   begin
      if Span = 0 then
         return Lo;
      end if;
      K := Natural (Real (U) * Real (Span + 1));
      if K > Span then
         K := Span;
      end if;
      return Lo + K;
   end Next_Natural;

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Clamp (X, Lo, Hi : Real) return Real is
   begin
      if X < Lo then
         return Lo;
      elsif X > Hi then
         return Hi;
      else
         return X;
      end if;
   end Clamp;

   ---------------------------------------------------------------------------
   -- Metropolis acceptance
   ---------------------------------------------------------------------------

   function Accept_Probability
     (Delta_E : Real; Temperature : Non_Negative) return Unit_Interval
   is
      Arg : Real;
   begin
      if Delta_E <= 0.0 then
         return 1.0;
      end if;
      if Temperature = 0.0 then
         return 0.0;
      end if;
      Arg := Delta_E / Temperature;
      if Arg > 80.0 then
         return 0.0;
      end if;
      return Unit_Interval (Exp (-Arg));
   end Accept_Probability;

   function Metropolis_Accept
     (Delta_E     : Real;
      Temperature : Non_Negative;
      State       : in out RNG_State) return Boolean
   is
      P : constant Unit_Interval :=
        Accept_Probability (Delta_E, Temperature);
      U : constant Unit_Interval := Next_Unit (State);
   begin
      return U < P;
   end Metropolis_Accept;

   ---------------------------------------------------------------------------
   -- Cooling
   ---------------------------------------------------------------------------

   function Cool_Geometric
     (T : Non_Negative; Alpha : Unit_Interval) return Non_Negative
   is
   begin
      return Non_Negative (Real (Alpha) * Real (T));
   end Cool_Geometric;

   function Cool_Linear
     (T, T0, T_Min : Non_Negative; Progress : Unit_Interval)
      return Non_Negative
   is
      pragma Unreferenced (T);
      P : constant Real := Real (Progress);
      V : Real;
   begin
      V := Real (T0) + (Real (T_Min) - Real (T0)) * P;
      if V < 0.0 then
         return 0.0;
      end if;
      return Non_Negative (V);
   end Cool_Linear;

   ---------------------------------------------------------------------------
   -- Built-in objectives
   ---------------------------------------------------------------------------

   function Double_Well (X : Real) return Real is
      X2 : constant Real := X * X;
   begin
      return (X2 - 1.0) * (X2 - 1.0) + 0.15 * X;
   end Double_Well;

   function Rastrigin_1D (X : Real) return Real is
   begin
      return X * X - 10.0 * Cos (Two_Pi * X) + 10.0;
   end Rastrigin_1D;

   function Quadratic (X : Real) return Real is
   begin
      return X * X;
   end Quadratic;

   function Shifted_Quadratic (X : Real) return Real is
      D : constant Real := X - 3.0;
   begin
      return D * D;
   end Shifted_Quadratic;

   ---------------------------------------------------------------------------
   -- Proposal helper
   ---------------------------------------------------------------------------

   function Propose
     (X     : Real;
      Cfg   : Config;
      State : in out RNG_State;
      Lo    : Real;
      Hi    : Real) return Real
   is
      Dx : Real;
   begin
      if Cfg.Use_Gaussian_Step then
         Dx := Cfg.Step * Next_Gaussian (State);
      else
         Dx := Next_Uniform (State, -Cfg.Step, Cfg.Step);
      end if;
      return Clamp (X + Dx, Lo, Hi);
   end Propose;

   ---------------------------------------------------------------------------
   -- 1-D continuous SA
   ---------------------------------------------------------------------------

   function Minimize_1D
     (Objective : Objective_Fn;
      X0        : Real;
      Cfg       : Config;
      Seed      : Natural;
      Lo        : Real := -1.0E6;
      Hi        : Real := 1.0E6) return Result
   is
      State  : RNG_State;
      X      : Real;
      E      : Real;
      Xp     : Real;
      Ep     : Real;
      Best_X : Real;
      Best_E : Real;
      T      : Non_Negative;
      Acc    : Boolean;
      R      : Result;
      Progress : Unit_Interval;
   begin
      if Objective = null then
         raise Invalid_Argument with "Minimize_1D: null Objective";
      end if;
      if Lo >= Hi then
         raise Invalid_Argument with "Minimize_1D: Lo >= Hi";
      end if;
      if Cfg.T_Min > Cfg.T0 then
         raise Invalid_Argument with "Minimize_1D: T_Min > T0";
      end if;

      Seed_RNG (State, Seed);
      X      := Clamp (X0, Lo, Hi);
      E      := Objective (X);
      Best_X := X;
      Best_E := E;
      T      := Cfg.T0;

      for Iter in 1 .. Cfg.Max_Iters loop
         Xp := Propose (X, Cfg, State, Lo, Hi);
         Ep := Objective (Xp);

         Acc := Metropolis_Accept (Ep - E, T, State);
         if Acc then
            X := Xp;
            E := Ep;
            R.Accept_Count := R.Accept_Count + 1;
         end if;

         if E < Best_E then
            Best_E := E;
            Best_X := X;
         end if;

         --  Cool on schedule
         if Iter rem Cfg.Cool_Every = 0 then
            case Cfg.Kind is
               when Geometric =>
                  T := Cool_Geometric (T, Cfg.Alpha);
               when Linear =>
                  Progress :=
                    Unit_Interval
                      (Real (Iter) / Real (Cfg.Max_Iters));
                  T := Cool_Linear (T, Cfg.T0, Cfg.T_Min, Progress);
            end case;
         end if;

         R.Iters := Iter;
         R.Final_T := T;

         exit when T <= Cfg.T_Min;
      end loop;

      R.Best_X := Best_X;
      R.Best_E := Best_E;
      return R;
   end Minimize_1D;

   ---------------------------------------------------------------------------
   -- TSP-lite
   ---------------------------------------------------------------------------

   function Tour_Length
     (T : Tour; D : Dist_Matrix) return Non_Negative
   is
      Len : Real := 0.0;
      A, B : City_Index;
   begin
      for I in T'First .. T'Last - 1 loop
         A := T (I);
         B := T (I + 1);
         Len := Len + Real (D (A, B));
      end loop;
      --  Close the tour
      A := T (T'Last);
      B := T (T'First);
      Len := Len + Real (D (A, B));
      return Non_Negative (Len);
   end Tour_Length;

   function Minimize_TSP
     (D     : Dist_Matrix;
      Cfg   : Config;
      Seed  : Natural;
      Start : Tour) return TSP_Result
   is
      N      : constant City_Count := Start'Length;
      Last_C : constant City_Index := City_Index (N);
      State  : RNG_State;
      Cur    : Tour (1 .. Last_C);
      Best   : Tour (1 .. Last_C);
      Len    : Non_Negative;
      Best_L : Non_Negative;
      New_L  : Non_Negative;
      T      : Non_Negative;
      I, J   : Natural;
      Tmp    : City_Index;
      Acc    : Boolean;
      R      : TSP_Result;
      Progress : Unit_Interval;
      Trial  : Tour (1 .. Last_C);
   begin
      if Cfg.T_Min > Cfg.T0 then
         raise Invalid_Argument with "Minimize_TSP: T_Min > T0";
      end if;

      Seed_RNG (State, Seed);
      Cur := Start;
      Best := Start;
      Len := Tour_Length (Cur, D);
      Best_L := Len;
      T := Cfg.T0;

      for Iter in 1 .. Cfg.Max_Iters loop
         Trial := Cur;
         --  Swap two distinct positions
         I := Next_Natural (State, 1, Natural (N));
         loop
            J := Next_Natural (State, 1, Natural (N));
            exit when J /= I;
         end loop;
         Tmp := Trial (City_Index (I));
         Trial (City_Index (I)) := Trial (City_Index (J));
         Trial (City_Index (J)) := Tmp;

         New_L := Tour_Length (Trial, D);
         Acc := Metropolis_Accept
           (Real (New_L) - Real (Len), T, State);
         if Acc then
            Cur := Trial;
            Len := New_L;
            R.Accept_Count := R.Accept_Count + 1;
         end if;

         if Len < Best_L then
            Best_L := Len;
            Best := Cur;
         end if;

         if Iter rem Cfg.Cool_Every = 0 then
            case Cfg.Kind is
               when Geometric =>
                  T := Cool_Geometric (T, Cfg.Alpha);
               when Linear =>
                  Progress :=
                    Unit_Interval
                      (Real (Iter) / Real (Cfg.Max_Iters));
                  T := Cool_Linear (T, Cfg.T0, Cfg.T_Min, Progress);
            end case;
         end if;

         R.Iters := Iter;
         R.Final_T := T;
         exit when T <= Cfg.T_Min;
      end loop;

      R.N := N;
      R.Best_Length := Best_L;
      for K in Best'Range loop
         R.Best_Tour (K) := Best (K);
      end loop;
      return R;
   end Minimize_TSP;

end Simulated_Annealing;
