--  Pareto_Interpolation body — Wikipedia two-point estimator, MLE fit,
--  PDF/CDF/Quantile, and median / class interpolation helpers.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions;

package body Pareto_Interpolation
  with SPARK_Mode => Off
is

   package Math renames Ada.Numerics.Elementary_Functions;

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Float; Tol : Float := Near_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Is_Positive (X : Float) return Boolean is
   begin
      return X > 0.0;
   end Is_Positive;

   function Validate_Parameters (Kappa, Theta : Float) return Status is
   begin
      if Kappa <= 0.0 or else Theta <= 0.0 then
         return Bad_Parameters;
      else
         return Ok;
      end if;
   end Validate_Parameters;

   function Validate_Cumulative
     (A, B, Pa, Pb : Float) return Status
   is
   begin
      if not (A > 0.0 and then B > 0.0) then
         return Bad_Parameters;
      elsif A >= B then
         return Invalid_Proportions;
      elsif Pa <= Prop_Tol or else Pb <= Prop_Tol then
         return Invalid_Proportions;
      elsif Pa >= 1.0 - Prop_Tol or else Pb >= 1.0 - Prop_Tol then
         return Invalid_Proportions;
      elsif Pa >= Pb then
         --  Need strictly increasing CDF proportions for a < b.
         return Invalid_Proportions;
      elsif (1.0 - Pa) <= 0.0 or else (1.0 - Pb) <= 0.0 then
         return Invalid_Proportions;
      else
         return Ok;
      end if;
   end Validate_Cumulative;

   function Slice (S : Sample) return Observations is
   begin
      return S.X (0 .. S.Count - 1);
   end Slice;

   --  Safe power via logs: base^exp for base > 0.
   function Pow (Base, Exp : Float) return Float is
   begin
      if Base <= 0.0 then
         return 0.0;
      end if;
      return Math.Exp (Exp * Math.Log (Base));
   end Pow;

   ---------------------------------------------------------------------------
   -- PDF / CDF / Quantile
   ---------------------------------------------------------------------------

   function PDF
     (X : Float; Kappa, Theta : Float) return Eval_Result
   is
      Stat : constant Status := Validate_Parameters (Kappa, Theta);
      --  f(x) = θ · κ^θ / x^{θ+1} = θ · exp(θ log κ − (θ+1) log x)
      Log_Dens : Float;
   begin
      if Stat /= Ok then
         return (Value => 0.0, Stat => Stat, Success => False);
      end if;
      if X < Kappa then
         return (Value => 0.0, Stat => Ok, Success => True);
      end if;
      if X <= 0.0 then
         return (Value => 0.0, Stat => Ok, Success => True);
      end if;
      Log_Dens :=
        Math.Log (Theta)
        + Theta * Math.Log (Kappa)
        - (Theta + 1.0) * Math.Log (X);
      return (Value => Math.Exp (Log_Dens), Stat => Ok, Success => True);
   end PDF;

   function PDF (X : Float; P : Parameters) return Eval_Result is
   begin
      if not P.Success then
         return (Value => 0.0, Stat => P.Stat, Success => False);
      end if;
      return PDF (X, P.Kappa, P.Theta);
   end PDF;

   function CDF
     (X : Float; Kappa, Theta : Float) return Eval_Result
   is
      Stat : constant Status := Validate_Parameters (Kappa, Theta);
      Ratio : Float;
   begin
      if Stat /= Ok then
         return (Value => 0.0, Stat => Stat, Success => False);
      end if;
      if X < Kappa then
         return (Value => 0.0, Stat => Ok, Success => True);
      end if;
      --  F(x) = 1 − (κ/x)^θ = 1 − exp(θ (log κ − log x))
      Ratio := Math.Exp (Theta * (Math.Log (Kappa) - Math.Log (X)));
      return (Value => 1.0 - Ratio, Stat => Ok, Success => True);
   end CDF;

   function CDF (X : Float; P : Parameters) return Eval_Result is
   begin
      if not P.Success then
         return (Value => 0.0, Stat => P.Stat, Success => False);
      end if;
      return CDF (X, P.Kappa, P.Theta);
   end CDF;

   function Quantile
     (Prob : Float; Kappa, Theta : Float) return Eval_Result
   is
      Stat : constant Status := Validate_Parameters (Kappa, Theta);
      --  Q(p) = κ (1−p)^{−1/θ} = κ · exp( (−1/θ) log(1−p) )
      One_Minus : Float;
      Q         : Float;
   begin
      if Stat /= Ok then
         return (Value => 0.0, Stat => Stat, Success => False);
      end if;
      if Prob <= Prop_Tol or else Prob >= 1.0 - Prop_Tol then
         return (Value => 0.0, Stat => Invalid_Proportions, Success => False);
      end if;
      One_Minus := 1.0 - Prob;
      Q := Kappa * Math.Exp ((-1.0 / Theta) * Math.Log (One_Minus));
      return (Value => Q, Stat => Ok, Success => True);
   end Quantile;

   function Quantile (Prob : Float; P : Parameters) return Eval_Result is
   begin
      if not P.Success then
         return (Value => 0.0, Stat => P.Stat, Success => False);
      end if;
      return Quantile (Prob, P.Kappa, P.Theta);
   end Quantile;

   function Median (Kappa, Theta : Float) return Eval_Result is
      Stat : constant Status := Validate_Parameters (Kappa, Theta);
      M    : Float;
   begin
      if Stat /= Ok then
         return (Value => 0.0, Stat => Stat, Success => False);
      end if;
      --  median = κ · 2^{1/θ}
      M := Kappa * Pow (2.0, 1.0 / Theta);
      return (Value => M, Stat => Ok, Success => True);
   end Median;

   function Median (P : Parameters) return Eval_Result is
   begin
      if not P.Success then
         return (Value => 0.0, Stat => P.Stat, Success => False);
      end if;
      return Median (P.Kappa, P.Theta);
   end Median;

   ---------------------------------------------------------------------------
   -- Fit
   ---------------------------------------------------------------------------

   function Fit_From_Cumulative
     (A, B, Pa, Pb : Float) return Parameters
   is
      Stat  : constant Status := Validate_Cumulative (A, B, Pa, Pb);
      Theta : Float;
      Kappa : Float;
      Diff_P : Float;
      Denom  : Float;
   begin
      if Stat /= Ok then
         return
           (Kappa => 0.0, Theta => 0.0, Stat => Stat, Success => False);
      end if;

      --  θ̂ = [log(1−Pa) − log(1−Pb)] / [log b − log a]
      --     = log((1−Pa)/(1−Pb)) / log(b/a)
      Theta :=
        (Math.Log (1.0 - Pa) - Math.Log (1.0 - Pb))
        / (Math.Log (B) - Math.Log (A));

      if Theta <= 0.0 then
         return
           (Kappa => 0.0, Theta => 0.0,
            Stat => Bad_Parameters, Success => False);
      end if;

      --  κ̂ = [(Pb − Pa) / (a^{−θ} − b^{−θ})]^{1/θ}
      Diff_P := Pb - Pa;
      Denom  := Pow (A, -Theta) - Pow (B, -Theta);
      if Diff_P <= 0.0 or else Denom <= 0.0 then
         return
           (Kappa => 0.0, Theta => 0.0,
            Stat => Bad_Parameters, Success => False);
      end if;
      Kappa := Pow (Diff_P / Denom, 1.0 / Theta);

      if Kappa <= 0.0 then
         return
           (Kappa => 0.0, Theta => 0.0,
            Stat => Bad_Parameters, Success => False);
      end if;

      return
        (Kappa => Kappa, Theta => Theta, Stat => Ok, Success => True);
   end Fit_From_Cumulative;

   function Fit_From_Cumulative (C : Cumulative_Pair) return Parameters is
   begin
      if not C.Valid then
         return Fit_From_Cumulative (C.A, C.B, C.Pa, C.Pb);
      end if;
      return Fit_From_Cumulative (C.A, C.B, C.Pa, C.Pb);
   end Fit_From_Cumulative;

   function Fit_From_Sample (X : Observations) return Parameters is
      N     : Natural;
      Kappa : Float;
      Sum_L : Float := 0.0;
      Theta : Float;
      Xi    : Float;
   begin
      if X'Length = 0 then
         return
           (Kappa => 0.0, Theta => 0.0,
            Stat => Empty_Sample, Success => False);
      end if;
      if X'Length > Max_Samples then
         return
           (Kappa => 0.0, Theta => 0.0,
            Stat => Dimension_Error, Success => False);
      end if;

      N := X'Length;

      --  κ̂ = min x_i; all must be > 0
      Kappa := X (X'First);
      for I in X'Range loop
         Xi := X (I);
         if Xi <= 0.0 then
            return
              (Kappa => 0.0, Theta => 0.0,
               Stat => Bad_Parameters, Success => False);
         end if;
         if Xi < Kappa then
            Kappa := Xi;
         end if;
      end loop;

      if Kappa <= 0.0 then
         return
           (Kappa => 0.0, Theta => 0.0,
            Stat => Bad_Parameters, Success => False);
      end if;

      --  θ̂ = n / Σ log(x_i / κ̂)
      for I in X'Range loop
         Xi := X (I);
         if Xi < Kappa then
            --  Should not happen; guard float noise
            return
              (Kappa => 0.0, Theta => 0.0,
               Stat => Bad_Parameters, Success => False);
         end if;
         --  When Xi = Kappa, log term is 0 — MLE needs some Xi > κ
         Sum_L := Sum_L + Math.Log (Xi / Kappa);
      end loop;

      if Sum_L <= 0.0 then
         --  All observations equal to min → undefined θ
         return
           (Kappa => 0.0, Theta => 0.0,
            Stat => Bad_Parameters, Success => False);
      end if;

      Theta := Float (N) / Sum_L;
      if Theta <= 0.0 then
         return
           (Kappa => 0.0, Theta => 0.0,
            Stat => Bad_Parameters, Success => False);
      end if;

      return
        (Kappa => Kappa, Theta => Theta, Stat => Ok, Success => True);
   end Fit_From_Sample;

   function Fit_From_Sample (S : Sample) return Parameters is
   begin
      if not S.Valid or else S.Count = 0 then
         return
           (Kappa => 0.0, Theta => 0.0,
            Stat => Empty_Sample, Success => False);
      end if;
      return Fit_From_Sample (S.X (0 .. S.Count - 1));
   end Fit_From_Sample;

   ---------------------------------------------------------------------------
   -- Interpolation helpers
   ---------------------------------------------------------------------------

   function Interpolate_Median
     (A, B, Pa, Pb : Float) return Eval_Result
   is
      P : constant Parameters := Fit_From_Cumulative (A, B, Pa, Pb);
   begin
      return Median (P);
   end Interpolate_Median;

   function Interpolate_Median (C : Cumulative_Pair) return Eval_Result is
   begin
      return Interpolate_Median (C.A, C.B, C.Pa, C.Pb);
   end Interpolate_Median;

   function Interpolate_Quantile
     (Prob : Float; A, B, Pa, Pb : Float) return Eval_Result
   is
      P : constant Parameters := Fit_From_Cumulative (A, B, Pa, Pb);
   begin
      return Quantile (Prob, P);
   end Interpolate_Quantile;

   function Interpolate_In_Class
     (Lo, Hi, P_Lo, P_Hi, Prob : Float) return Eval_Result
   is
   begin
      --  Same two-point fit; then evaluate any quantile (class context
      --  is educational — Prob often lies between P_Lo and P_Hi).
      return Interpolate_Quantile (Prob, Lo, Hi, P_Lo, P_Hi);
   end Interpolate_In_Class;

   ---------------------------------------------------------------------------
   -- Builders
   ---------------------------------------------------------------------------

   function Make_Cumulative
     (A, B, Pa, Pb : Float) return Cumulative_Pair
   is
      C : Cumulative_Pair;
   begin
      C.A := A;
      C.B := B;
      C.Pa := Pa;
      C.Pb := Pb;
      C.Valid := Validate_Cumulative (A, B, Pa, Pb) = Ok;
      return C;
   end Make_Cumulative;

   function Make_Sample (X : Observations) return Sample is
      S : Sample;
      N : constant Natural := X'Length;
      K : Natural := 0;
   begin
      S.Count := N;
      for I in X'Range loop
         S.X (K) := X (I);
         K := K + 1;
      end loop;
      S.Valid := N > 0;
      return S;
   end Make_Sample;

   --  Tiny educational LCG for reproducible synthetic draws.
   function Next_U (State : in out Natural) return Float is
      --  Numerical Recipes–style constants (mod 2^31)
      M : constant := 2_147_483_647;
      A : constant := 48_271;
   begin
      State := Natural ((Long_Integer (State) * Long_Integer (A))
                       mod Long_Integer (M));
      if State = 0 then
         State := 1;
      end if;
      return Float (State) / Float (M);
   end Next_U;

   function Make_Pareto_Sample
     (Count : Sample_Count;
      Kappa, Theta : Float;
      Seed  : Natural := 1) return Sample
   is
      S     : Sample;
      State : Natural := (if Seed = 0 then 1 else Seed);
      U     : Float;
      Q     : Eval_Result;
   begin
      S.Count := Count;
      for I in 0 .. Count - 1 loop
         U := Next_U (State);
         --  Keep U away from 0 and 1 for Inverse_CDF
         if U < 1.0E-6 then
            U := 1.0E-6;
         elsif U > 1.0 - 1.0E-6 then
            U := 1.0 - 1.0E-6;
         end if;
         Q := Quantile (U, Kappa, Theta);
         if Q.Success then
            S.X (I) := Q.Value;
         else
            S.X (I) := Kappa;
         end if;
      end loop;
      S.Valid := True;
      return S;
   end Make_Pareto_Sample;

   function Make_Example (Kind : Example_Kind) return Parameters is
   begin
      case Kind is
         when Wiki_Income_Example =>
            --  Approximate scale from the Wikipedia income narrative
            return Fit_From_Cumulative (35_000.0, 40_000.0, 0.45, 0.55);
         when Unit_Pareto =>
            return
              (Kappa => 1.0, Theta => 1.0, Stat => Ok, Success => True);
         when Heavy_Tail =>
            return
              (Kappa => 1.0, Theta => 0.5, Stat => Ok, Success => True);
         when Thin_Tail =>
            return
              (Kappa => 10.0, Theta => 3.0, Stat => Ok, Success => True);
      end case;
   end Make_Example;

   function Make_Wiki_Cumulative return Cumulative_Pair is
   begin
      return Make_Cumulative (35_000.0, 40_000.0, 0.45, 0.55);
   end Make_Wiki_Cumulative;

end Pareto_Interpolation;
