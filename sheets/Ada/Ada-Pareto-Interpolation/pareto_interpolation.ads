--  Pareto_Interpolation — Ada 2023 educational package for Wikipedia
--  "Pareto interpolation": estimate medians / quantiles for a
--  Pareto-distributed population from grouped or sample income-style
--  data (economics). Family parameterized by κ > 0 (minimum) and
--  Pareto index θ > 0. Educational Float; numerically careful logs.
--  Primary source:
--  https://en.wikipedia.org/wiki/Pareto_interpolation
--  Siblings (README): Ada-Polynomial-Interpolation, Ada-Neville,
--  Ada-Spline-Interpolation; upcoming Tricubic, Nearest-neighbor,
--  Lanczos resampling.

pragma Ada_2022;

package Pareto_Interpolation
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types (educational Float)
   ---------------------------------------------------------------------------

   --  Cap on iid samples for MLE fit (educational).
   Max_Samples : constant := 512;

   subtype Sample_Count is Natural range 0 .. Max_Samples;
   subtype Sample_Index is Natural range 0 .. Max_Samples - 1;

   --  Packed positive observations x_0 .. x_{N-1} (income-style values).
   type Observations is array (Natural range <>) of Float;

   --  Ok                   : succeeded
   --  Bad_Parameters       : κ ≤ 0 or θ ≤ 0 (or resulting estimate)
   --  Empty_Sample         : no observations / zero length
   --  Invalid_Proportions  : Pa, Pb not in (0,1), or a ≥ b, or 1-P ≤ 0
   --  Dimension_Error      : over Max_Samples / empty bounds
   --  Ill_Started          : internal setup could not proceed
   type Status is
     (Ok,
      Bad_Parameters,
      Empty_Sample,
      Invalid_Proportions,
      Dimension_Error,
      Ill_Started);

   --  Fitted / prescribed Pareto(κ, θ).
   type Parameters is record
      Kappa   : Float := 0.0;   -- κ > 0 (minimum)
      Theta   : Float := 0.0;   -- θ > 0 (Pareto index)
      Stat    : Status := Ill_Started;
      Success : Boolean := False;
   end record;

   type Eval_Result is record
      Value   : Float := 0.0;
      Stat    : Status := Ill_Started;
      Success : Boolean := False;
   end record;

   --  Packed sample: valid entries are X(0 .. Count-1).
   type Sample is record
      X     : Observations (Sample_Index) := [others => 0.0];
      Count : Sample_Count := 0;
      Valid : Boolean := False;
   end record;

   --  Two cumulative class points a < b with proportions P_a, P_b
   --  (classic Wikipedia textbook setup).
   type Cumulative_Pair is record
      A, B     : Float := 0.0;   -- class / income bounds, a < b
      Pa, Pb   : Float := 0.0;   -- sample proportions below a, b
      Valid    : Boolean := False;
   end record;

   type Example_Kind is
     (Wiki_Income_Example,
      Unit_Pareto,
      Heavy_Tail,
      Thin_Tail);

   Invalid_Argument : exception;

   Epsilon_Tol : constant Float := 1.0E-6;
   Near_Tol    : constant Float := 1.0E-5;
   Prop_Tol    : constant Float := 1.0E-9;  -- open (0,1) for proportions

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Float; Tol : Float := Near_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Is_Positive (X : Float) return Boolean
     with Global => null;
   --  True iff X > 0.0.

   function Validate_Parameters (Kappa, Theta : Float) return Status
     with Global => null;
   --  Bad_Parameters if κ ≤ 0 or θ ≤ 0; else Ok.

   function Validate_Cumulative
     (A, B, Pa, Pb : Float) return Status
     with Global => null;
   --  Invalid_Proportions / Bad_Parameters / Ok for the two-point setup.

   function Slice (S : Sample) return Observations
     with Pre => S.Valid and then S.Count > 0, Global => null;
   --  S.X (0 .. Count-1)

   ---------------------------------------------------------------------------
   -- PDF / CDF / Quantile for Pareto(κ, θ)
   --   PDF: f(x) = θ κ^θ / x^{θ+1}   (x ≥ κ), else 0
   --   CDF: F(x) = 1 − (κ/x)^θ       (x ≥ κ), else 0
   --   Q(p) = κ (1−p)^{−1/θ}         (0 < p < 1)
   --   median = κ · 2^{1/θ}
   ---------------------------------------------------------------------------

   function PDF
     (X : Float; Kappa, Theta : Float) return Eval_Result;
   --  Density at X; Bad_Parameters if κ,θ invalid.

   function PDF (X : Float; P : Parameters) return Eval_Result;
   --  Uses P.Kappa, P.Theta when P.Success; else forwards P.Stat.

   function CDF
     (X : Float; Kappa, Theta : Float) return Eval_Result;

   function CDF (X : Float; P : Parameters) return Eval_Result;

   function Quantile
     (Prob : Float; Kappa, Theta : Float) return Eval_Result;
   --  Inverse CDF; Prob must be in (0,1). Alias of Inverse_CDF.

   function Quantile (Prob : Float; P : Parameters) return Eval_Result;

   function Inverse_CDF
     (Prob : Float; Kappa, Theta : Float) return Eval_Result
     renames Quantile;

   function Inverse_CDF
     (Prob : Float; P : Parameters) return Eval_Result
     renames Quantile;

   function Median (Kappa, Theta : Float) return Eval_Result;
   --  κ · 2^{1/θ}

   function Median (P : Parameters) return Eval_Result;

   ---------------------------------------------------------------------------
   -- Fit / estimate parameters
   ---------------------------------------------------------------------------

   function Fit_From_Cumulative
     (A, B, Pa, Pb : Float) return Parameters;
   --  Wikipedia two-point estimator:
   --    θ̂ = [log(1−Pa) − log(1−Pb)] / [log b − log a]
   --    κ̂ = [(Pb−Pa) / (a^{−θ̂} − b^{−θ̂})]^{1/θ̂}

   function Fit_From_Cumulative (C : Cumulative_Pair) return Parameters;

   function Fit_From_Sample (X : Observations) return Parameters;
   --  Classical MLE: κ̂ = min x_i, θ̂ = n / Σ log(x_i/κ̂).
   --  Requires all x_i > 0; Empty_Sample / Bad_Parameters otherwise.

   function Fit_From_Sample (S : Sample) return Parameters;

   ---------------------------------------------------------------------------
   -- Median / class interpolation (Wikipedia)
   ---------------------------------------------------------------------------

   function Interpolate_Median
     (A, B, Pa, Pb : Float) return Eval_Result;
   --  Fit two-point Pareto then return κ̂ · 2^{1/θ̂}.

   function Interpolate_Median (C : Cumulative_Pair) return Eval_Result;

   function Interpolate_Median (P : Parameters) return Eval_Result
     renames Median;
   --  Same as Median once parameters are known.

   function Interpolate_Quantile
     (Prob : Float; A, B, Pa, Pb : Float) return Eval_Result;
   --  Fit two-point then Quantile(Prob).

   function Interpolate_In_Class
     (Lo, Hi, P_Lo, P_Hi, Prob : Float) return Eval_Result;
   --  Educational class helper: treat (Lo,Hi) with cumulative proportions
   --  P_Lo, P_Hi as the Wikipedia (a,b,Pa,Pb) pair, fit Pareto, then
   --  return the Prob-quantile (typically Prob in (P_Lo, P_Hi) for a
   --  within-class interpolate; any Prob in (0,1) is accepted).

   ---------------------------------------------------------------------------
   -- Builders / sample data
   ---------------------------------------------------------------------------

   function Make_Cumulative
     (A, B, Pa, Pb : Float) return Cumulative_Pair
     with Global => null;
   --  Packs fields; Valid iff Validate_Cumulative = Ok.

   function Make_Sample (X : Observations) return Sample
     with Pre => X'Length > 0 and then X'Length <= Max_Samples,
          Global => null;

   function Make_Pareto_Sample
     (Count : Sample_Count;
      Kappa, Theta : Float;
      Seed  : Natural := 1) return Sample
     with Pre =>
       Count >= 1
       and then Count <= Max_Samples
       and then Kappa > 0.0
       and then Theta > 0.0,
          Global => null;
   --  Synthetic Pareto draws via inverse CDF + deterministic LCG uniforms
   --  (educational reproducibility; not cryptographic).

   function Make_Example (Kind : Example_Kind) return Parameters
     with Global => null;
   --  Preset (κ, θ) for demos / tests.

   function Make_Wiki_Cumulative return Cumulative_Pair
     with Global => null;
   --  Wikipedia narrative: a=35000, b=40000, Pa=0.45, Pb=0.55.

end Pareto_Interpolation;
