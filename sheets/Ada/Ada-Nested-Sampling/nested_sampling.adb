--  Nested_Sampling body — Skilling nested sampling (2004/2006).

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Nested_Sampling
  with SPARK_Mode => Off
is

   package EF is new Ada.Numerics.Generic_Elementary_Functions (Real);

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Safe_Log (X : Real) return Real is
   begin
      if X <= 0.0 then
         return -1.0E30;
      else
         return EF.Log (X);
      end if;
   end Safe_Log;

   function Log_Sum (A, B : Real) return Real is
      M : Real;
   begin
      if A < -1.0E29 and then B < -1.0E29 then
         return -1.0E30;
      elsif A > B then
         M := A;
         return M + Safe_Log (1.0 + EF.Exp (B - M));
      else
         M := B;
         return M + Safe_Log (1.0 + EF.Exp (A - M));
      end if;
   end Log_Sum;

   ---------------------------------------------------------------------------
   -- Prior volume / shell weight
   ---------------------------------------------------------------------------

   function Prior_Volume
     (Iteration : Natural;
      N_Live    : Positive;
      Schedule  : Volume_Schedule := Exponential_Shrink) return Unit_Interval
   is
      N : constant Real := Real (N_Live);
      X : Real;
   begin
      if Iteration = 0 then
         return 1.0;
      end if;
      case Schedule is
         when Exponential_Shrink =>
            X := EF.Exp (-Real (Iteration) / N);
         when Debiased_Shrink =>
            declare
               Factor : constant Real := 1.0 - 1.0 / N;
               Acc    : Real := 1.0;
            begin
               for K in 1 .. Iteration loop
                  Acc := Acc * Factor;
               end loop;
               X := Acc;
            end;
      end case;
      if X < 0.0 then
         return 0.0;
      elsif X > 1.0 then
         return 1.0;
      else
         return X;
      end if;
   end Prior_Volume;

   function Shell_Weight
     (X_Prev, X_Curr : Unit_Interval) return Non_Negative
   is
      W : constant Real := X_Prev - X_Curr;
   begin
      if W < 0.0 then
         return 0.0;
      else
         return W;
      end if;
   end Shell_Weight;

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
   begin
      State := State * Multiplier + Increment;
      --  Upper 24 bits → [0, 1)
      return Real (State / 2**8) / Real (2**24);
   end Next_Unit;

   function Next_Real
     (State : in out RNG_State; Lo, Hi : Real) return Real
   is
   begin
      return Lo + Next_Unit (State) * (Hi - Lo);
   end Next_Real;

   ---------------------------------------------------------------------------
   -- Built-in models
   ---------------------------------------------------------------------------

   --  ∫_{-5}^{5} exp(-t²/2) dt / 10  via dense midpoint (reference value).
   --  √(2π) ≈ 2.506628238, erf approx: ∫_{-5}^{5} φ(t)√(2π) ≈ 1 so
   --  ∫ exp(-t²/2) dt ≈ √(2π) → Z ≈ √(2π)/10 ≈ 0.2506628238 (truncation tiny).
   Gaussian_Bump_Z : constant Positive_Real := 0.250_662_827_4;

   function Model_Dim (Model : Built_In_Model) return Dim_Count is
      pragma Unreferenced (Model);
   begin
      return 1;
   end Model_Dim;

   function Model_Low (Model : Built_In_Model) return Param_Vector is
      V : Param_Vector := [others => 0.0];
   begin
      case Model is
         when Flat_Unit | Exponential_Unit | Theta_Unit =>
            V (1) := 0.0;
         when Gaussian_Bump =>
            V (1) := -5.0;
      end case;
      return V;
   end Model_Low;

   function Model_High (Model : Built_In_Model) return Param_Vector is
      V : Param_Vector := [others => 0.0];
   begin
      case Model is
         when Flat_Unit | Exponential_Unit | Theta_Unit =>
            V (1) := 1.0;
         when Gaussian_Bump =>
            V (1) := 5.0;
      end case;
      return V;
   end Model_High;

   function Analytic_Evidence (Model : Built_In_Model) return Positive_Real is
      E_Inv : constant Real := EF.Exp (-1.0);
   begin
      case Model is
         when Flat_Unit =>
            return 1.0;
         when Exponential_Unit =>
            --  ∫_0^1 exp(-θ) dθ = 1 - e^{-1}
            return 1.0 - E_Inv;
         when Gaussian_Bump =>
            return Gaussian_Bump_Z;
         when Theta_Unit =>
            return 0.5;
      end case;
   end Analytic_Evidence;

   function Built_In_Likelihood
     (Model : Built_In_Model; Theta : Param_Vector; Dim : Dim_Count)
      return Real
   is
      T : Real;
   begin
      if Dim < 1 then
         return 0.0;
      end if;
      T := Theta (1);
      case Model is
         when Flat_Unit =>
            return 1.0;
         when Exponential_Unit =>
            return EF.Exp (-T);
         when Gaussian_Bump =>
            return EF.Exp (-0.5 * T * T);
         when Theta_Unit =>
            return T;
      end case;
   end Built_In_Likelihood;

   function In_Prior_Box
     (Theta, Low, High : Param_Vector; Dim : Dim_Count) return Boolean
   is
   begin
      for D in 1 .. Dim_Index (Dim) loop
         if Theta (D) < Low (D) or else Theta (D) > High (D) then
            return False;
         end if;
      end loop;
      return True;
   end In_Prior_Box;

   function Built_In_Prior_Density
     (Model : Built_In_Model; Theta : Param_Vector; Dim : Dim_Count)
      return Real
   is
      Low  : constant Param_Vector := Model_Low (Model);
      High : constant Param_Vector := Model_High (Model);
      Vol  : Real := 1.0;
      D_Use : constant Dim_Count :=
        (if Dim = 0 then Model_Dim (Model) else Dim);
   begin
      if D_Use < 1 then
         return 0.0;
      end if;
      if not In_Prior_Box (Theta, Low, High, D_Use) then
         return 0.0;
      end if;
      for D in 1 .. Dim_Index (D_Use) loop
         Vol := Vol * (High (D) - Low (D));
      end loop;
      if Vol <= 0.0 then
         return 0.0;
      end if;
      return 1.0 / Vol;
   end Built_In_Prior_Density;

   ---------------------------------------------------------------------------
   -- Live set
   ---------------------------------------------------------------------------

   procedure Init_Live_From_Prior
     (Live   : out Live_Set;
      Params : Parameters;
      Likely : Likelihood_Fn;
      State  : in out RNG_State)
   is
      P : Live_Point;
   begin
      if Params.N_Live > Max_Live then
         raise Invalid_Argument with "N_Live out of range";
      end if;
      if Params.Dim = 0 then
         raise Invalid_Argument with "Dim out of range";
      end if;
      if Likely = null then
         raise Invalid_Argument with "Likelihood is null";
      end if;
      for D in 1 .. Dim_Index (Params.Dim) loop
         if Params.Low (D) > Params.High (D) then
            raise Invalid_Argument with "Low > High";
         end if;
      end loop;

      Live.Count := 0;
      Live.Dim   := Params.Dim;
      Live.Points := [others => <>];

      for I in 1 .. Live_Index (Params.N_Live) loop
         P.Dim := Params.Dim;
         P.Theta := [others => 0.0];
         for D in 1 .. Dim_Index (Params.Dim) loop
            P.Theta (D) :=
              Next_Real (State, Params.Low (D), Params.High (D));
         end loop;
         P.L := Likely (P.Theta, Params.Dim);
         Live.Points (I) := P;
         Live.Count := Live.Count + 1;
      end loop;
   end Init_Live_From_Prior;

   function Min_Likelihood_Index (Live : Live_Set) return Live_Index is
      Best : Live_Index := 1;
   begin
      for I in 2 .. Live_Index (Live.Count) loop
         if Live.Points (I).L < Live.Points (Best).L then
            Best := I;
         end if;
      end loop;
      return Best;
   end Min_Likelihood_Index;

   function Mean_Likelihood (Live : Live_Set) return Real is
      S : Real := 0.0;
   begin
      for I in 1 .. Live_Index (Live.Count) loop
         S := S + Live.Points (I).L;
      end loop;
      return S / Real (Live.Count);
   end Mean_Likelihood;

   procedure Replace_Lowest_MCMC
     (Live       : in out Live_Set;
      L_Star     : Real;
      Params     : Parameters;
      Likely     : Likelihood_Fn;
      State      : in out RNG_State;
      Accepted   : out Natural)
   is
      Worst   : constant Live_Index := Min_Likelihood_Index (Live);
      Start_I : Live_Index;
      Curr    : Live_Point;
      Prop    : Live_Point;
      Step    : Real;
      U       : Real;
      Pick    : Natural;
   begin
      Accepted := 0;
      if Live.Count < 1 then
         raise Invalid_Argument with "empty live set";
      end if;
      if Likely = null then
         raise Invalid_Argument with "Likelihood is null";
      end if;

      --  Start from a random live point (preferably not the condemned one).
      if Live.Count = 1 then
         Start_I := 1;
      else
         Pick :=
           Natural (Next_Unit (State) * Real (Live.Count - 1));
         --  Map 0 .. Count-2 → indices skipping Worst
         Start_I := 1;
         declare
            Seen : Natural := 0;
         begin
            for I in 1 .. Live_Index (Live.Count) loop
               if I /= Worst then
                  if Seen = Pick then
                     Start_I := I;
                     exit;
                  end if;
                  Seen := Seen + 1;
               end if;
            end loop;
         end;
      end if;

      Curr := Live.Points (Start_I);

      for Step_I in 1 .. Params.MCMC_Steps loop
         Prop := Curr;
         for D in 1 .. Dim_Index (Params.Dim) loop
            Step :=
              Params.Proposal_Scale
              * (Params.High (D) - Params.Low (D));
            --  Symmetric uniform proposal in [-Step, Step]
            U := Next_Real (State, -Step, Step);
            Prop.Theta (D) := Curr.Theta (D) + U;
         end loop;
         if In_Prior_Box (Prop.Theta, Params.Low, Params.High, Params.Dim)
         then
            Prop.L := Likely (Prop.Theta, Params.Dim);
            if Prop.L > L_Star then
               Curr := Prop;
               Accepted := Accepted + 1;
            end if;
         end if;
      end loop;

      --  If MCMC never accepted, fall back to rejection sampling from prior.
      if Accepted = 0 then
         declare
            Tries : constant Positive := 10_000;
            Ok    : Boolean := False;
         begin
            for T in 1 .. Tries loop
               Prop.Dim := Params.Dim;
               Prop.Theta := [others => 0.0];
               for D in 1 .. Dim_Index (Params.Dim) loop
                  Prop.Theta (D) :=
                    Next_Real (State, Params.Low (D), Params.High (D));
               end loop;
               Prop.L := Likely (Prop.Theta, Params.Dim);
               if Prop.L > L_Star then
                  Curr := Prop;
                  Accepted := 1;
                  Ok := True;
                  exit;
               end if;
            end loop;
            if not Ok then
               --  Keep a copy of a surviving live point (constraint still holds).
               Curr := Live.Points (Start_I);
            end if;
         end;
      end if;

      Live.Points (Worst) := Curr;
   end Replace_Lowest_MCMC;

   ---------------------------------------------------------------------------
   -- Main driver
   ---------------------------------------------------------------------------

   function Run_Nested_Sampling
     (Params : Parameters;
      Likely : Likelihood_Fn) return Result
   is
      Live    : Live_Set;
      State   : RNG_State;
      R       : Result;
      X_Prev  : Unit_Interval;
      X_Curr  : Unit_Interval;
      W       : Non_Negative;
      L_I     : Real;
      Worst   : Live_Index;
      Acc     : Natural;
      Z       : Real := 0.0;
      Contrib : Real;
      Mean_L  : Real;
   begin
      if Params.N_Live < 2 then
         raise Invalid_Argument with "N_Live must be >= 2";
      end if;
      if Params.N_Live > Max_Live then
         raise Capacity_Exceeded with "N_Live > Max_Live";
      end if;
      if Params.Dim = 0 then
         raise Invalid_Argument with "Dim out of range";
      end if;
      if Likely = null then
         raise Invalid_Argument with "Likelihood is null";
      end if;
      if Params.Max_Iters > Max_Samples then
         raise Capacity_Exceeded with "Max_Iters > Max_Samples";
      end if;

      Seed_RNG (State, Params.Seed);
      Init_Live_From_Prior (Live, Params, Likely, State);

      X_Prev := 1.0;
      R.Num_Samples := 0;

      for Iter in 1 .. Params.Max_Iters loop
         Worst := Min_Likelihood_Index (Live);
         L_I := Live.Points (Worst).L;
         X_Curr := Prior_Volume (Iter, Params.N_Live, Params.Schedule);
         W := Shell_Weight (X_Prev, X_Curr);

         Z := Z + L_I * W;

         if R.Num_Samples = Max_Samples then
            raise Capacity_Exceeded with "sample buffer full";
         end if;
         R.Num_Samples := R.Num_Samples + 1;
         R.Samples (R.Num_Samples) :=
           (Theta  => Live.Points (Worst).Theta,
            L      => L_I,
            Weight => W,
            Dim    => Live.Dim);

         Replace_Lowest_MCMC
           (Live, L_I, Params, Likely, State, Acc);
         R.Last_MCMC_Accepted := Acc;

         R.Iters := Iter;
         R.Final_X := X_Curr;
         X_Prev := X_Curr;

         --  Stop when remaining prior mass contributes little.
         Contrib := L_I * X_Curr;
         if Z > 0.0 and then Contrib < Params.Tol * Z then
            exit;
         end if;
      end loop;

      R.Remainder := 0.0;
      if Params.Add_Remainder then
         Mean_L := Mean_Likelihood (Live);
         R.Remainder := X_Prev * Mean_L;
         if R.Remainder < 0.0 then
            R.Remainder := 0.0;
         end if;
         Z := Z + R.Remainder;
      end if;

      if Z < 0.0 then
         Z := 0.0;
      end if;
      R.Evidence := Z;
      R.Log_Evidence := Safe_Log (Z);
      return R;
   end Run_Nested_Sampling;


   function Likelihood_Flat
     (Theta : Param_Vector; Dim : Dim_Count) return Real
   is
   begin
      return Built_In_Likelihood (Flat_Unit, Theta, Dim);
   end Likelihood_Flat;

   function Likelihood_Exponential
     (Theta : Param_Vector; Dim : Dim_Count) return Real
   is
   begin
      return Built_In_Likelihood (Exponential_Unit, Theta, Dim);
   end Likelihood_Exponential;

   function Likelihood_Gaussian_Bump
     (Theta : Param_Vector; Dim : Dim_Count) return Real
   is
   begin
      return Built_In_Likelihood (Gaussian_Bump, Theta, Dim);
   end Likelihood_Gaussian_Bump;

   function Likelihood_Theta
     (Theta : Param_Vector; Dim : Dim_Count) return Real
   is
   begin
      return Built_In_Likelihood (Theta_Unit, Theta, Dim);
   end Likelihood_Theta;

   --  Closures for built-in models (package-level for 'Access).
   Active_Model : Built_In_Model := Flat_Unit;

   function Dispatch_Likelihood
     (Theta : Param_Vector; Dim : Dim_Count) return Real
   is
   begin
      return Built_In_Likelihood (Active_Model, Theta, Dim);
   end Dispatch_Likelihood;

   function Run_Built_In
     (Model  : Built_In_Model;
      Params : Parameters := (others => <>)) return Result
   is
      P : Parameters := Params;
   begin
      Active_Model := Model;
      P.Dim := Model_Dim (Model);
      P.Low := Model_Low (Model);
      P.High := Model_High (Model);
      case Model is
         when Flat_Unit | Exponential_Unit | Theta_Unit =>
            P.Proposal_Scale := 0.2;
         when Gaussian_Bump =>
            P.Proposal_Scale := 0.15;
      end case;
      return Run_Nested_Sampling (P, Dispatch_Likelihood'Access);
   end Run_Built_In;

end Nested_Sampling;
