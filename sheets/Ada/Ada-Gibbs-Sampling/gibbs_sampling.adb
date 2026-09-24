--  Gibbs_Sampling package body — bivariate Normal Gibbs (exact
--  conditionals) and Beta–Bernoulli conjugate full-conditional toy.

pragma Ada_2022;

with Ada.Numerics;
with Ada.Numerics.Elementary_Functions;
with Ada.Numerics.Float_Random;

package body Gibbs_Sampling is

   package EF renames Ada.Numerics.Elementary_Functions;
   package FR renames Ada.Numerics.Float_Random;

   Two_Pi : constant Real := 2.0 * Real (Ada.Numerics.Pi);

   -------------------------------------------------------------------------
   -- Local numeric helpers
   -------------------------------------------------------------------------

   function Log_R (X : Real) return Real is
   begin
      if X <= 0.0 then
         return -Real'Last / 4.0;
      else
         return Real (EF.Log (Float (X)));
      end if;
   end Log_R;

   function Sqrt_R (X : Real) return Real is
   begin
      if X <= 0.0 then
         return 0.0;
      else
         return Real (EF.Sqrt (Float (X)));
      end if;
   end Sqrt_R;

   function Cos_R (X : Real) return Real is
   begin
      return Real (EF.Cos (Float (X)));
   end Cos_R;

   function Power_R (Base, Expn : Real) return Real is
   begin
      if Base <= 0.0 then
         return 0.0;
      else
         return Real (EF.Exp (Float (Expn) * EF.Log (Float (Base))));
      end if;
   end Power_R;

   --  Uniform (0,1) avoiding exact 0 for logs / Box–Muller.
   function Unit_Open (Gen : in out FR.Generator) return Real is
      U : Real;
   begin
      loop
         U := Real (FR.Random (Gen));
         exit when U > 0.0 and then U < 1.0;
      end loop;
      return U;
   end Unit_Open;

   --  Standard normal via Box–Muller (one sample per call).
   function Std_Normal (Gen : in out FR.Generator) return Real is
      U1 : constant Real := Unit_Open (Gen);
      U2 : constant Real := Unit_Open (Gen);
   begin
      return Sqrt_R (-2.0 * Log_R (U1)) * Cos_R (Two_Pi * U2);
   end Std_Normal;

   function Gaussian
     (Gen : in out FR.Generator; Mu, Sigma : Real) return Real is
   begin
      return Mu + Sigma * Std_Normal (Gen);
   end Gaussian;

   -------------------------------------------------------------------------
   -- Gamma(shape, 1) via Marsaglia–Tsang; Beta via Gamma ratio
   -------------------------------------------------------------------------

   --  Marsaglia & Tsang (2000) for shape >= 1; boost for shape < 1.
   function Gamma_One
     (Gen : in out FR.Generator; Shape : Positive_Real) return Real
   is
      A : Real := Shape;
      D, C, X, V, U : Real;
      Boost : Real := 1.0;
   begin
      if A < 1.0 then
         --  Gamma(a) = Gamma(a+1) * U^{1/a}
         Boost := Power_R (Unit_Open (Gen), 1.0 / A);
         A := A + 1.0;
      end if;

      D := A - 1.0 / 3.0;
      C := 1.0 / Sqrt_R (9.0 * D);

      loop
         loop
            X := Std_Normal (Gen);
            V := 1.0 + C * X;
            exit when V > 0.0;
         end loop;
         V := V * V * V;
         U := Unit_Open (Gen);
         exit when U < 1.0 - 0.0331 * (X * X) * (X * X)
           or else Log_R (U) < 0.5 * X * X + D * (1.0 - V + Log_R (V));
      end loop;

      return D * V * Boost;
   end Gamma_One;

   function Sample_Beta
     (Gen : in out FR.Generator; A, B : Positive_Real) return Real
   is
      G1 : constant Real := Gamma_One (Gen, A);
      G2 : constant Real := Gamma_One (Gen, B);
      S  : constant Real := G1 + G2;
   begin
      if S <= 0.0 then
         return 0.5;
      else
         return G1 / S;
      end if;
   end Sample_Beta;

   -------------------------------------------------------------------------
   -- Welford / online bivariate moments
   -------------------------------------------------------------------------

   type Bi_Moments is record
      N     : Natural := 0;
      Mean_X, Mean_Y : Real := 0.0;
      Cxx, Cyy, Cxy  : Real := 0.0;
   end record;

   procedure Push (M : in out Bi_Moments; X, Y : Real) is
      Dx, Dy : Real;
   begin
      M.N := M.N + 1;
      Dx := X - M.Mean_X;
      Dy := Y - M.Mean_Y;
      M.Mean_X := M.Mean_X + Dx / Real (M.N);
      M.Mean_Y := M.Mean_Y + Dy / Real (M.N);
      M.Cxx := M.Cxx + Dx * (X - M.Mean_X);
      M.Cyy := M.Cyy + Dy * (Y - M.Mean_Y);
      M.Cxy := M.Cxy + Dx * (Y - M.Mean_Y);
   end Push;

   function Sample_Var (C : Real; N : Natural) return Real is
   begin
      if N < 2 then
         return 0.0;
      else
         return C / Real (N - 1);
      end if;
   end Sample_Var;

   type Uni_Moments is record
      N    : Natural := 0;
      Mean : Real    := 0.0;
      M2   : Real    := 0.0;
   end record;

   procedure Push_U (M : in out Uni_Moments; X : Real) is
      Diff, Diff2 : Real;
   begin
      M.N := M.N + 1;
      Diff := X - M.Mean;
      M.Mean := M.Mean + Diff / Real (M.N);
      Diff2 := X - M.Mean;
      M.M2 := M.M2 + Diff * Diff2;
   end Push_U;

   function Sample_Variance_U (M : Uni_Moments) return Real is
   begin
      if M.N < 2 then
         return 0.0;
      else
         return M.M2 / Real (M.N - 1);
      end if;
   end Sample_Variance_U;

   -------------------------------------------------------------------------
   -- Public helpers
   -------------------------------------------------------------------------

   function Conditional_Mean (Rho, Other : Real) return Real is
   begin
      return Rho * Other;
   end Conditional_Mean;

   function Conditional_Variance (Rho : Real) return Non_Negative is
      V : constant Real := 1.0 - Rho * Rho;
   begin
      if V <= 0.0 then
         return 0.0;
      else
         return Non_Negative (V);
      end if;
   end Conditional_Variance;

   function Conditional_Std_Dev (Rho : Real) return Non_Negative is
   begin
      return Non_Negative (Sqrt_R (Real (Conditional_Variance (Rho))));
   end Conditional_Std_Dev;

   function Valid_Correlation (Rho : Real) return Boolean is
   begin
      return abs (Rho) < 1.0 - Epsilon_Tol;
   end Valid_Correlation;

   function Posterior_Alpha
     (Alpha : Positive_Real; Successes : Natural) return Positive_Real is
   begin
      return Positive_Real (Alpha + Real (Successes));
   end Posterior_Alpha;

   function Posterior_Beta
     (Beta_P            : Positive_Real;
      Successes, Trials : Natural) return Positive_Real is
   begin
      return Positive_Real (Beta_P + Real (Trials - Successes));
   end Posterior_Beta;

   function Posterior_Mean
     (Alpha, Beta_P     : Positive_Real;
      Successes, Trials : Natural) return Unit_Fraction
   is
      A : constant Real := Real (Posterior_Alpha (Alpha, Successes));
      B : constant Real := Real (Posterior_Beta (Beta_P, Successes, Trials));
   begin
      return Unit_Fraction (A / (A + B));
   end Posterior_Mean;

   -------------------------------------------------------------------------
   -- Core: bivariate Normal Gibbs
   -------------------------------------------------------------------------

   function Sample_Bivariate_Normal
     (Cfg : Config := (others => <>)) return Result
   is
      Gen   : FR.Generator;
      X     : Real := Cfg.Start_X;
      Y     : Real := Cfg.Start_Y;
      Sigma : Real;
      Mu    : Real;
      Mom   : Bi_Moments;
      R     : Result;
      Vx, Vy, Den : Real;
   begin
      if not Valid_Correlation (Cfg.Rho) then
         raise Invalid_Argument with "Gibbs_Sampling: |Rho| must be < 1";
      end if;
      if Cfg.Burn_In >= Cfg.Steps then
         raise Invalid_Argument with "Gibbs_Sampling: Burn_In >= Steps";
      end if;

      Sigma := Real (Conditional_Std_Dev (Cfg.Rho));
      FR.Reset (Gen, Cfg.Seed);

      for T in 1 .. Cfg.Steps loop
         --  X | Y
         Mu := Conditional_Mean (Cfg.Rho, Y);
         X := Gaussian (Gen, Mu, Sigma);
         --  Y | X
         Mu := Conditional_Mean (Cfg.Rho, X);
         Y := Gaussian (Gen, Mu, Sigma);

         if T > Cfg.Burn_In then
            Push (Mom, X, Y);
            if Cfg.Keep_Samples and then R.Stored < Max_Store then
               R.Stored := R.Stored + 1;
               R.Samples_X (R.Stored) := X;
               R.Samples_Y (R.Stored) := Y;
            end if;
         end if;
      end loop;

      R.Mean_X := Mom.Mean_X;
      R.Mean_Y := Mom.Mean_Y;
      R.Var_X := Sample_Var (Mom.Cxx, Mom.N);
      R.Var_Y := Sample_Var (Mom.Cyy, Mom.N);
      R.Cov_XY := Sample_Var (Mom.Cxy, Mom.N);
      R.N_Kept := Mom.N;

      Vx := R.Var_X;
      Vy := R.Var_Y;
      Den := Sqrt_R (Vx * Vy);
      if Den > Epsilon_Tol then
         R.Correlation := R.Cov_XY / Den;
      else
         R.Correlation := 0.0;
      end if;

      return R;
   end Sample_Bivariate_Normal;

   -------------------------------------------------------------------------
   -- Optional: Beta–Bernoulli conjugate toy
   -------------------------------------------------------------------------

   function Sample_Beta_Bernoulli
     (Cfg : Beta_Bernoulli_Config := (others => <>)) return Beta_Bernoulli_Result
   is
      Gen : FR.Generator;
      A   : Positive_Real;
      B   : Positive_Real;
      P   : Real;
      Mom : Uni_Moments;
      Res : Beta_Bernoulli_Result;
   begin
      if Cfg.Successes > Cfg.Trials then
         raise Invalid_Argument with
           "Gibbs_Sampling: Successes > Trials";
      end if;
      if Cfg.Burn_In >= Cfg.Steps then
         raise Invalid_Argument with "Gibbs_Sampling: Burn_In >= Steps";
      end if;

      A := Posterior_Alpha (Cfg.Alpha, Cfg.Successes);
      B := Posterior_Beta (Cfg.Beta_P, Cfg.Successes, Cfg.Trials);
      FR.Reset (Gen, Cfg.Seed);

      for T in 1 .. Cfg.Steps loop
         P := Sample_Beta (Gen, A, B);
         if T > Cfg.Burn_In then
            Push_U (Mom, P);
         end if;
      end loop;

      Res.Mean_P := Mom.Mean;
      Res.Var_P := Sample_Variance_U (Mom);
      Res.N_Kept := Mom.N;
      return Res;
   end Sample_Beta_Bernoulli;

end Gibbs_Sampling;
