--  Bayesian_Statistics body — Bayes updates, Beta / Normal conjugates,
--  incomplete-beta CDF / quantile, discrete evidence / Bayes factors.

pragma Ada_2022;

with Ada.Numerics;                       use Ada.Numerics;
with Ada.Numerics.Generic_Elementary_Functions;

package body Bayesian_Statistics
  with SPARK_Mode => Off
is

   package Math is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Math;

   Log_Sentinel : constant Real := -1.0E30;

   -------------------------------------------------------------------------
   -- Helpers
   -------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Safe_Log (X : Real) return Real is
   begin
      if X <= 0.0 then
         return Log_Sentinel;
      end if;
      return Log (X);
   end Safe_Log;

   function Log_Sum (A, B : Real) return Real is
      M : Real;
   begin
      if A <= Log_Sentinel / 2.0 and then B <= Log_Sentinel / 2.0 then
         return Log_Sentinel;
      end if;
      if A > B then
         M := A;
         return M + Log (1.0 + Exp (B - M));
      else
         M := B;
         return M + Log (1.0 + Exp (A - M));
      end if;
   end Log_Sum;

   function Clamp_Unit (X : Real) return Unit_Interval is
   begin
      if X < 0.0 then
         return 0.0;
      elsif X > 1.0 then
         return 1.0;
      else
         return X;
      end if;
   end Clamp_Unit;

   procedure Require_Prob (P : Real; Name : String) is
   begin
      if P < 0.0 or else P > 1.0 then
         raise Invalid_Argument with Name & " not in [0,1]";
      end if;
   end Require_Prob;

   procedure Require_Positive_Beta (P : Beta_Params) is
   begin
      if P.Alpha <= 0.0 or else P.Beta <= 0.0 then
         raise Invalid_Argument with "Beta parameters must be positive";
      end if;
   end Require_Positive_Beta;

   -------------------------------------------------------------------------
   -- RNG (Numerical Recipes–style LCG, period 2^32)
   -------------------------------------------------------------------------

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
      return Real (State) / Real (RNG_State'Last);
   end Next_Unit;

   -------------------------------------------------------------------------
   -- Log Gamma (Lanczos approximation, g=7)
   -------------------------------------------------------------------------

   function Log_Gamma (Z : Real) return Real is
      --  Lanczos coefficients for g = 7, n = 9 (Wikipedia / Numerical Recipes)
      C0 : constant Real := 0.99999999999980993;
      C1 : constant Real := 676.5203681218851;
      C2 : constant Real := -1259.1392167224028;
      C3 : constant Real := 771.32342877783015;
      C4 : constant Real := -176.61502916214059;
      C5 : constant Real := 12.507343278686905;
      C6 : constant Real := -0.13857109526572012;
      C7 : constant Real := 9.984369654079156E-6;
      C8 : constant Real := 1.5056327351493116E-7;
      G  : constant Real := 7.0;
      X  : Real;
      T  : Real;
      Half_Log_Two_Pi : constant Real := 0.5 * Log (2.0 * Pi);
   begin
      if Z < 0.5 then
         --  Reflection: Γ(z)Γ(1−z) = π / sin(πz)
         return Log (Pi) - Log (Sin (Pi * Z)) - Log_Gamma (1.0 - Z);
      end if;
      X := C0
        + C1 / Z
        + C2 / (Z + 1.0)
        + C3 / (Z + 2.0)
        + C4 / (Z + 3.0)
        + C5 / (Z + 4.0)
        + C6 / (Z + 5.0)
        + C7 / (Z + 6.0)
        + C8 / (Z + 7.0);
      T := Z + G - 0.5;
      return Half_Log_Two_Pi + (Z - 0.5) * Log (T) - T + Log (X);
   end Log_Gamma;

   function Log_Beta (A, B : Real) return Real is
   begin
      return Log_Gamma (A) + Log_Gamma (B) - Log_Gamma (A + B);
   end Log_Beta;

   -------------------------------------------------------------------------
   -- Regularized incomplete beta I_x(a,b)
   -- Series when x < (a+1)/(a+b+2), else continued fraction via identity
   -- I_x(a,b) = 1 - I_{1-x}(b,a).
   -------------------------------------------------------------------------

   function Incomplete_Beta_Series
     (X, A, B : Real) return Real
   is
      --  I_x(a,b) = x^a / (a B(a,b)) * _2F_1(a, 1-b; a+1; x).
      --  Term ratio: (a+n)(1-b+n) / ((a+1+n)(n+1)) * x.
      Front : Real;
      Sum   : Real := 1.0;
      Term  : Real := 1.0;
      N     : Natural := 0;
      Ratio : Real;
   begin
      if X = 0.0 then
         return 0.0;
      end if;
      Front := Exp (A * Log (X) - Log_Beta (A, B)) / A;
      loop
         exit when N >= 500;
         Ratio := (A + Real (N)) * (1.0 - B + Real (N))
           / ((A + 1.0 + Real (N)) * Real (N + 1));
         Term := Term * Ratio * X;
         Sum := Sum + Term;
         N := N + 1;
         exit when abs (Term) < 1.0E-14 * (1.0 + abs (Sum));
      end loop;
      return Front * Sum;
   end Incomplete_Beta_Series;

   function Incomplete_Beta_CF
     (X, A, B : Real) return Real
   is
      --  Lentz continued fraction for incomplete beta (NR §6.4).
      Max_Iter : constant := 200;
      Tiny     : constant Real := 1.0E-30;
      EPS      : constant Real := 1.0E-12;
      Front    : Real;
      QAB, QAP, QAM : Real;
      D, C, H, AA, Del : Real;
      M : Natural;
      M2 : Real;
   begin
      if X = 0.0 then
         return 0.0;
      end if;
      Front := Exp (A * Log (X) + B * Log (1.0 - X) - Log_Beta (A, B))
        / A;
      QAB := A + B;
      QAP := A + 1.0;
      QAM := A - 1.0;
      C := 1.0;
      D := 1.0 - QAB * X / QAP;
      if abs (D) < Tiny then
         D := Tiny;
      end if;
      D := 1.0 / D;
      H := D;
      M := 1;
      loop
         exit when M > Max_Iter;
         M2 := Real (2 * M);
         --  Even step
         AA := Real (M) * (B - Real (M)) * X
           / ((QAM + M2) * (A + M2));
         D := 1.0 + AA * D;
         if abs (D) < Tiny then
            D := Tiny;
         end if;
         C := 1.0 + AA / C;
         if abs (C) < Tiny then
            C := Tiny;
         end if;
         D := 1.0 / D;
         H := H * D * C;
         --  Odd step
         AA := -(A + Real (M)) * (QAB + Real (M)) * X
           / ((A + M2) * (QAP + M2));
         D := 1.0 + AA * D;
         if abs (D) < Tiny then
            D := Tiny;
         end if;
         C := 1.0 + AA / C;
         if abs (C) < Tiny then
            C := Tiny;
         end if;
         D := 1.0 / D;
         Del := D * C;
         H := H * Del;
         exit when abs (Del - 1.0) < EPS;
         M := M + 1;
      end loop;
      return Front * H;
   end Incomplete_Beta_CF;

   function Regularized_Incomplete_Beta
     (X : Unit_Interval; A, B : Real) return Unit_Interval
   is
      Use_Series : Boolean;
      Raw        : Real;
   begin
      if A <= 0.0 or else B <= 0.0 then
         raise Invalid_Argument with "incomplete beta needs A,B > 0";
      end if;
      if X <= 0.0 then
         return 0.0;
      end if;
      if X >= 1.0 then
         return 1.0;
      end if;
      --  Use CF on the side where x is smaller for faster convergence
      --  (Numerical Recipes strategy). Series kept as fallback for tiny x.
      Use_Series := X < (A + 1.0) / (A + B + 2.0);
      if Use_Series then
         if X < 1.0E-8 then
            Raw := Incomplete_Beta_Series (X, A, B);
         else
            Raw := Incomplete_Beta_CF (X, A, B);
         end if;
         return Clamp_Unit (Raw);
      else
         if (1.0 - X) < 1.0E-8 then
            Raw := Incomplete_Beta_Series (1.0 - X, B, A);
            return Clamp_Unit (1.0 - Raw);
         end if;
         Raw := Incomplete_Beta_CF (1.0 - X, B, A);
         return Clamp_Unit (1.0 - Raw);
      end if;
   end Regularized_Incomplete_Beta;

   -------------------------------------------------------------------------
   -- Events / Bayes
   -------------------------------------------------------------------------

   function Is_Valid_Probability (P : Real) return Boolean is
   begin
      return P >= 0.0 and then P <= 1.0;
   end Is_Valid_Probability;

   function Posterior_Prob
     (Prior_A              : Unit_Interval;
      Likelihood_B_Given_A : Unit_Interval;
      Evidence_B           : Real) return Unit_Interval
   is
      Num : Real;
   begin
      Require_Prob (Prior_A, "Prior_A");
      Require_Prob (Likelihood_B_Given_A, "Likelihood_B_Given_A");
      if Evidence_B <= 0.0 then
         raise Invalid_Argument with "Evidence_B must be positive";
      end if;
      Num := Likelihood_B_Given_A * Prior_A;
      return Clamp_Unit (Num / Evidence_B);
   end Posterior_Prob;

   function Evidence_From_Complement
     (Prior_A                  : Unit_Interval;
      Likelihood_B_Given_A     : Unit_Interval;
      Likelihood_B_Given_Not_A : Unit_Interval) return Unit_Interval
   is
   begin
      Require_Prob (Prior_A, "Prior_A");
      Require_Prob (Likelihood_B_Given_A, "Likelihood_B_Given_A");
      Require_Prob (Likelihood_B_Given_Not_A, "Likelihood_B_Given_Not_A");
      return Clamp_Unit
        (Likelihood_B_Given_A * Prior_A
         + Likelihood_B_Given_Not_A * (1.0 - Prior_A));
   end Evidence_From_Complement;

   function Posterior_Prob_Complement
     (Prior_A                  : Unit_Interval;
      Likelihood_B_Given_A     : Unit_Interval;
      Likelihood_B_Given_Not_A : Unit_Interval) return Unit_Interval
   is
      Ev  : Unit_Interval;
      Num : Real;
   begin
      Ev := Evidence_From_Complement
        (Prior_A, Likelihood_B_Given_A, Likelihood_B_Given_Not_A);
      if Ev <= 0.0 then
         raise Invalid_Argument with "evidence P(B) is zero";
      end if;
      Num := Likelihood_B_Given_A * Prior_A;
      return Clamp_Unit (Num / Ev);
   end Posterior_Prob_Complement;

   -------------------------------------------------------------------------
   -- Beta–Bernoulli
   -------------------------------------------------------------------------

   function Beta_Update
     (Prior     : Beta_Params;
      Successes : Natural;
      Trials    : Natural) return Beta_Params
   is
   begin
      Require_Positive_Beta (Prior);
      if Successes > Trials then
         raise Invalid_Argument with "Successes > Trials";
      end if;
      return
        (Alpha => Prior.Alpha + Real (Successes),
         Beta  => Prior.Beta + Real (Trials - Successes));
   end Beta_Update;

   function Beta_Mean (P : Beta_Params) return Unit_Interval is
   begin
      Require_Positive_Beta (P);
      return Clamp_Unit (P.Alpha / (P.Alpha + P.Beta));
   end Beta_Mean;

   function Beta_Mode (P : Beta_Params) return Unit_Interval is
   begin
      Require_Positive_Beta (P);
      if P.Alpha > 1.0 and then P.Beta > 1.0 then
         return Clamp_Unit
           ((P.Alpha - 1.0) / (P.Alpha + P.Beta - 2.0));
      elsif P.Alpha < 1.0 and then P.Beta >= 1.0 then
         return 0.0;
      elsif P.Beta < 1.0 and then P.Alpha >= 1.0 then
         return 1.0;
      else
         --  Flat Beta(1,1) or both < 1 (U-shaped): report midpoint.
         return 0.5;
      end if;
   end Beta_Mode;

   function Beta_Variance (P : Beta_Params) return Non_Negative is
      S : Real;
   begin
      Require_Positive_Beta (P);
      S := P.Alpha + P.Beta;
      return (P.Alpha * P.Beta) / (S * S * (S + 1.0));
   end Beta_Variance;

   function Beta_PDF (X : Unit_Interval; P : Beta_Params) return Non_Negative is
   begin
      Require_Positive_Beta (P);
      if X <= 0.0 or else X >= 1.0 then
         if (X = 0.0 and then P.Alpha < 1.0)
           or else (X = 1.0 and then P.Beta < 1.0)
         then
            return Real'Last / 4.0;  --  diverges; return large sentinel
         end if;
         if (X = 0.0 and then P.Alpha = 1.0)
           or else (X = 1.0 and then P.Beta = 1.0)
         then
            return Exp (-Log_Beta (P.Alpha, P.Beta));
         end if;
         return 0.0;
      end if;
      return Exp
        ((P.Alpha - 1.0) * Log (X)
         + (P.Beta - 1.0) * Log (1.0 - X)
         - Log_Beta (P.Alpha, P.Beta));
   end Beta_PDF;

   function Beta_Log_PDF
     (X : Open_Unit; P : Beta_Params) return Real
   is
   begin
      Require_Positive_Beta (P);
      if X <= 0.0 or else X >= 1.0 then
         raise Invalid_Argument with "Beta_Log_PDF needs x in (0,1)";
      end if;
      return (P.Alpha - 1.0) * Log (X)
        + (P.Beta - 1.0) * Log (1.0 - X)
        - Log_Beta (P.Alpha, P.Beta);
   end Beta_Log_PDF;

   function Beta_Quantile
     (P_Level : Unit_Interval; P : Beta_Params) return Unit_Interval
   is
      Lo, Hi, Mid : Real;
      F_Mid       : Real;
      Iter        : Natural := 0;
   begin
      Require_Positive_Beta (P);
      Require_Prob (P_Level, "P_Level");
      if P_Level <= 0.0 then
         return 0.0;
      end if;
      if P_Level >= 1.0 then
         return 1.0;
      end if;
      Lo := 0.0;
      Hi := 1.0;
      loop
         Mid := 0.5 * (Lo + Hi);
         F_Mid := Regularized_Incomplete_Beta (Mid, P.Alpha, P.Beta);
         if F_Mid < P_Level then
            Lo := Mid;
         else
            Hi := Mid;
         end if;
         Iter := Iter + 1;
         exit when Iter >= 80 or else (Hi - Lo) < 1.0E-12;
      end loop;
      return Clamp_Unit (0.5 * (Lo + Hi));
   end Beta_Quantile;

   function Equal_Tailed_Credible_Interval
     (P     : Beta_Params;
      Level : Unit_Interval := 0.95) return Credible_Interval
   is
      Alpha_Tail : Real;
      CI         : Credible_Interval;
   begin
      Require_Positive_Beta (P);
      if Level <= 0.0 or else Level >= 1.0 then
         raise Invalid_Argument with "Level must be in (0,1)";
      end if;
      Alpha_Tail := 0.5 * (1.0 - Level);
      CI.Level  := Level;
      CI.Lower  := Beta_Quantile (Alpha_Tail, P);
      CI.Upper  := Beta_Quantile (1.0 - Alpha_Tail, P);
      return CI;
   end Equal_Tailed_Credible_Interval;

   function Contains
     (CI : Credible_Interval; Value : Unit_Interval) return Boolean
   is
   begin
      return Value >= CI.Lower and then Value <= CI.Upper;
   end Contains;

   -------------------------------------------------------------------------
   -- Normal conjugate
   -------------------------------------------------------------------------

   function Normal_Conjugate_Update
     (Prior        : Normal_Params;
      Sample_Mean  : Real;
      N            : Positive;
      Obs_Variance : Positive_Real) return Normal_Params
   is
      Prec0, Prec_Data, Prec_Post : Real;
      Mu_Post, Var_Post           : Real;
   begin
      Prec0      := 1.0 / Prior.Sigma2;
      Prec_Data  := Real (N) / Obs_Variance;
      Prec_Post  := Prec0 + Prec_Data;
      Var_Post   := 1.0 / Prec_Post;
      Mu_Post    := Var_Post
        * (Prec0 * Prior.Mu + Prec_Data * Sample_Mean);
      return (Mu => Mu_Post, Sigma2 => Var_Post);
   end Normal_Conjugate_Update;

   function Normal_PDF (X : Real; P : Normal_Params) return Non_Negative is
      Z : Real;
   begin
      Z := (X - P.Mu) / Sqrt (P.Sigma2);
      return Exp (-0.5 * Z * Z)
        / Sqrt (2.0 * Pi * P.Sigma2);
   end Normal_PDF;

   -------------------------------------------------------------------------
   -- Evidence / Bayes factors
   -------------------------------------------------------------------------

   function Discrete_Evidence
     (Likelihoods : Real_Array;
      Priors      : Real_Array) return Non_Negative
   is
      Z   : Real := 0.0;
      Sum : Real := 0.0;
   begin
      if Likelihoods'Length = 0 or else Priors'Length = 0 then
         raise Invalid_Argument with "empty hypothesis arrays";
      end if;
      if Likelihoods'Length /= Priors'Length then
         raise Invalid_Argument with "likelihood/prior length mismatch";
      end if;
      if Likelihoods'Length > Max_Hypotheses then
         raise Capacity_Exceeded with "too many hypotheses";
      end if;
      if Likelihoods'First /= Priors'First
        or else Likelihoods'Last /= Priors'Last
      then
         raise Invalid_Argument with "index bounds must match";
      end if;
      for I in Likelihoods'Range loop
         if Likelihoods (I) < 0.0 then
            raise Invalid_Argument with "negative likelihood";
         end if;
         if Priors (I) < 0.0 then
            raise Invalid_Argument with "negative prior";
         end if;
         Sum := Sum + Priors (I);
         Z   := Z + Likelihoods (I) * Priors (I);
      end loop;
      if Sum <= 0.0 then
         raise Invalid_Argument with "priors sum to zero";
      end if;
      return Z;
   end Discrete_Evidence;

   function Bayes_Factor
     (Likelihood_H1, Likelihood_H2 : Real) return Positive_Real
   is
   begin
      if Likelihood_H1 < 0.0 or else Likelihood_H2 < 0.0 then
         raise Invalid_Argument with "likelihoods must be non-negative";
      end if;
      if Likelihood_H2 <= 0.0 then
         raise Invalid_Argument with "Likelihood_H2 must be positive";
      end if;
      return Likelihood_H1 / Likelihood_H2;
   end Bayes_Factor;

   function Posterior_Odds
     (Prior_Odds, Bayes_Factor_12 : Real) return Positive_Real
   is
   begin
      if Prior_Odds <= 0.0 or else Bayes_Factor_12 <= 0.0 then
         raise Invalid_Argument with "odds and BF must be positive";
      end if;
      return Prior_Odds * Bayes_Factor_12;
   end Posterior_Odds;

end Bayesian_Statistics;
