--  Metropolis_Hastings package body — MCMC sampling (RW-Metropolis,
--  general Hastings ratio, discrete Bernoulli / 1D Ising toys).

pragma Ada_2022;

with Ada.Numerics;
with Ada.Numerics.Elementary_Functions;
with Ada.Numerics.Float_Random;

package body Metropolis_Hastings is

   package EF renames Ada.Numerics.Elementary_Functions;
   package FR renames Ada.Numerics.Float_Random;

   Two_Pi : constant Real := 2.0 * Real (Ada.Numerics.Pi);

   -------------------------------------------------------------------------
   -- Local numeric helpers
   -------------------------------------------------------------------------

   function Exp_R (X : Real) return Real is
   begin
      if X > 700.0 then
         return Real'Last / 4.0;
      elsif X < -700.0 then
         return 0.0;
      else
         return Real (EF.Exp (Float (X)));
      end if;
   end Exp_R;

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
   -- Welford accumulator
   -------------------------------------------------------------------------

   type Moments is record
      N    : Natural := 0;
      Mean : Real    := 0.0;
      M2   : Real    := 0.0;
   end record;

   procedure Push (M : in out Moments; X : Real) is
      Diff  : Real;
      Diff2 : Real;
   begin
      M.N := M.N + 1;
      Diff := X - M.Mean;
      M.Mean := M.Mean + Diff / Real (M.N);
      Diff2 := X - M.Mean;
      M.M2 := M.M2 + Diff * Diff2;
   end Push;

   function Sample_Variance (M : Moments) return Real is
   begin
      if M.N < 2 then
         return 0.0;
      else
         return M.M2 / Real (M.N - 1);
      end if;
   end Sample_Variance;


   function Finish
     (Mom : Moments; Accepted, Proposed : Natural) return Result
   is
      R : Result;
   begin
      R.Mean := Mom.Mean;
      R.Variance := Sample_Variance (Mom);
      R.N_Kept := Mom.N;
      R.N_Accepted := Accepted;
      R.N_Proposed := Proposed;
      if Proposed = 0 then
         R.Accept_Rate := 0.0;
      else
         R.Accept_Rate :=
           Unit_Fraction (Real (Accepted) / Real (Proposed));
      end if;
      return R;
   end Finish;

   -------------------------------------------------------------------------
   -- Public helpers
   -------------------------------------------------------------------------

   function Accept_Probability (Log_Alpha : Real) return Unit_Fraction is
   begin
      if Log_Alpha >= 0.0 then
         return 1.0;
      else
         return Unit_Fraction (Exp_R (Log_Alpha));
      end if;
   end Accept_Probability;

   function Log_Hastings_Ratio
     (Log_Pi_Current : Real;
      Log_Pi_Prop    : Real;
      Log_Q_Ratio    : Real := 0.0) return Real is
   begin
      return Log_Pi_Prop - Log_Pi_Current + Log_Q_Ratio;
   end Log_Hastings_Ratio;

   function Log_Std_Normal (X : Real) return Real is
   begin
      return -0.5 * X * X;
   end Log_Std_Normal;

   function Log_Normal (X, Mu, Sigma : Real) return Real is
      Z : constant Real := (X - Mu) / Sigma;
   begin
      return -0.5 * Z * Z;
   end Log_Normal;

   function Log_Normal_Full (X, Mu, Sigma : Real) return Real is
      Z : constant Real := (X - Mu) / Sigma;
   begin
      return -0.5 * Z * Z - Log_R (Sigma) - 0.5 * Log_R (Two_Pi);
   end Log_Normal_Full;

   -------------------------------------------------------------------------
   -- Educational targets
   -------------------------------------------------------------------------

   function Target_Std_Normal (X : Real) return Real is
   begin
      return Log_Std_Normal (X);
   end Target_Std_Normal;

   function Target_Normal_Mu2 (X : Real) return Real is
   begin
      return Log_Normal (X, 2.0, 1.0);
   end Target_Normal_Mu2;

   function Target_Normal_Wide (X : Real) return Real is
   begin
      return Log_Normal (X, 0.0, 2.0);
   end Target_Normal_Wide;

   function Target_Bimodal (X : Real) return Real is
      A : constant Real := Exp_R (-0.5 * (X + 2.0) * (X + 2.0));
      B : constant Real := Exp_R (-0.5 * (X - 2.0) * (X - 2.0));
   begin
      return Log_R (A + B);
   end Target_Bimodal;

   function Proposal_Std_Normal (X : Real) return Real is
   begin
      return Log_Normal_Full (X, 0.0, 1.0);
   end Proposal_Std_Normal;

   -------------------------------------------------------------------------
   -- 1D symmetric Gaussian RW Metropolis
   -------------------------------------------------------------------------

   function Sample_1D
     (Log_Pi : Log_Target_1D;
      Cfg    : Config := (others => <>)) return Result
   is
      Gen       : FR.Generator;
      X         : Real := Cfg.Start;
      Log_Px    : Real;
      Xp        : Real;
      Log_Pxp   : Real;
      Log_A     : Real;
      Accepted  : Natural := 0;
      Mom       : Moments;
      Stored_N  : Store_Count := 0;
      Samples_B : Sample_Array (1 .. Max_Store) := [others => 0.0];
      R         : Result;
      Keep_From : Natural;
   begin
      if Log_Pi = null then
         raise Invalid_Argument with "Log_Pi is null";
      end if;
      if Cfg.Burn_In >= Cfg.Steps then
         raise Invalid_Argument with "Burn_In must be < Steps";
      end if;

      FR.Reset (Gen, Cfg.Seed);
      Log_Px := Log_Pi (X);
      Keep_From := Cfg.Burn_In + 1;

      for T in 1 .. Cfg.Steps loop
         Xp := Gaussian (Gen, X, Cfg.Proposal_Sigma);
         Log_Pxp := Log_Pi (Xp);
         Log_A := Log_Hastings_Ratio (Log_Px, Log_Pxp, 0.0);

         if Unit_Open (Gen) <= Accept_Probability (Log_A) then
            X := Xp;
            Log_Px := Log_Pxp;
            Accepted := Accepted + 1;
         end if;

         if T >= Keep_From then
            Push (Mom, X);
            if Cfg.Keep_Samples and then Stored_N < Max_Store then
               Stored_N := Stored_N + 1;
               Samples_B (Stored_N) := X;
            end if;
         end if;
      end loop;

      R := Finish (Mom, Accepted, Cfg.Steps);
      R.Stored := Stored_N;
      if Stored_N > 0 then
         R.Samples (1 .. Stored_N) := Samples_B (1 .. Stored_N);
      end if;
      return R;
   end Sample_1D;

   -------------------------------------------------------------------------
   function Sample_1D_Independent
     (Log_Pi : Log_Target_1D;
      Log_Q  : Log_Density_1D;
      Cfg    : Config := (others => <>)) return Result
   is
      Gen       : FR.Generator;
      X         : Real := Cfg.Start;
      Log_Px    : Real;
      Log_Qx    : Real;
      Xp        : Real;
      Log_Pxp   : Real;
      Log_Qxp   : Real;
      Log_A     : Real;
      Accepted  : Natural := 0;
      Mom       : Moments;
      Stored_N  : Store_Count := 0;
      Samples_B : Sample_Array (1 .. Max_Store) := [others => 0.0];
      R         : Result;
      Keep_From : Natural;
      Mu_Prop   : constant Real := Cfg.Start;
      Sig_Prop  : constant Real := Cfg.Proposal_Sigma;
   begin
      if Log_Pi = null or else Log_Q = null then
         raise Invalid_Argument with "null density";
      end if;
      if Cfg.Burn_In >= Cfg.Steps then
         raise Invalid_Argument with "Burn_In must be < Steps";
      end if;

      FR.Reset (Gen, Cfg.Seed);
      Log_Px := Log_Pi (X);
      Log_Qx := Log_Q (X);
      Keep_From := Cfg.Burn_In + 1;

      for T in 1 .. Cfg.Steps loop
         Xp := Gaussian (Gen, Mu_Prop, Sig_Prop);
         Log_Pxp := Log_Pi (Xp);
         Log_Qxp := Log_Q (Xp);
         --  Independent MH: log q(x|x') − log q(x'|x) = log q(x) − log q(x')
         Log_A := Log_Hastings_Ratio (Log_Px, Log_Pxp, Log_Qx - Log_Qxp);

         if Unit_Open (Gen) <= Accept_Probability (Log_A) then
            X := Xp;
            Log_Px := Log_Pxp;
            Log_Qx := Log_Qxp;
            Accepted := Accepted + 1;
         end if;

         if T >= Keep_From then
            Push (Mom, X);
            if Cfg.Keep_Samples and then Stored_N < Max_Store then
               Stored_N := Stored_N + 1;
               Samples_B (Stored_N) := X;
            end if;
         end if;
      end loop;

      R := Finish (Mom, Accepted, Cfg.Steps);
      R.Stored := Stored_N;
      if Stored_N > 0 then
         R.Samples (1 .. Stored_N) := Samples_B (1 .. Stored_N);
      end if;
      return R;
   end Sample_1D_Independent;

   -------------------------------------------------------------------------
   -- Multi-D isotropic RW Metropolis
   -------------------------------------------------------------------------

   function Sample_ND
     (Log_Pi : Log_Target_ND;
      Cfg    : Config_ND) return Result_ND
   is
      Gen       : FR.Generator;
      X         : Point (1 .. Cfg.D) := Cfg.Start;
      Xp        : Point (1 .. Cfg.D);
      Log_Px    : Real;
      Log_Pxp   : Real;
      Log_A     : Real;
      Accepted  : Natural := 0;
      Keep_From : Natural;
      R         : Result_ND (Cfg.D);
      --  Per-coordinate Welford
      Means     : Point (1 .. Cfg.D) := [others => 0.0];
      M2s       : Point (1 .. Cfg.D) := [others => 0.0];
      N_Kept    : Natural := 0;
      Diff     : Real;
      Diff2    : Real;
   begin
      if Log_Pi = null then
         raise Invalid_Argument with "Log_Pi is null";
      end if;
      if Cfg.Burn_In >= Cfg.Steps then
         raise Invalid_Argument with "Burn_In must be < Steps";
      end if;

      FR.Reset (Gen, Cfg.Seed);
      Log_Px := Log_Pi (X);
      Keep_From := Cfg.Burn_In + 1;

      for T in 1 .. Cfg.Steps loop
         for I in 1 .. Cfg.D loop
            Xp (I) := Gaussian (Gen, X (I), Cfg.Proposal_Sigma);
         end loop;
         Log_Pxp := Log_Pi (Xp);
         Log_A := Log_Hastings_Ratio (Log_Px, Log_Pxp, 0.0);

         if Unit_Open (Gen) <= Accept_Probability (Log_A) then
            X := Xp;
            Log_Px := Log_Pxp;
            Accepted := Accepted + 1;
         end if;

         if T >= Keep_From then
            N_Kept := N_Kept + 1;
            for I in 1 .. Cfg.D loop
               Diff := X (I) - Means (I);
               Means (I) := Means (I) + Diff / Real (N_Kept);
               Diff2 := X (I) - Means (I);
               M2s (I) := M2s (I) + Diff * Diff2;
            end loop;
         end if;
      end loop;

      R.Mean := Means;
      R.N_Kept := N_Kept;
      R.N_Accepted := Accepted;
      R.N_Proposed := Cfg.Steps;
      if N_Kept >= 2 then
         for I in 1 .. Cfg.D loop
            R.Variance (I) := M2s (I) / Real (N_Kept - 1);
         end loop;
      end if;
      R.Accept_Rate :=
        Unit_Fraction (Real (Accepted) / Real (Cfg.Steps));
      return R;
   end Sample_ND;

   -------------------------------------------------------------------------
   -- Discrete Bernoulli flip Metropolis
   -------------------------------------------------------------------------

   function Sample_Bernoulli
     (P   : Unit_Fraction;
      Cfg : Config := (others => <>)) return Result
   is
      Gen       : FR.Generator;
      --  State encoded as Real 0.0 / 1.0 for Result moments
      S         : Integer := 0;
      Sp        : Integer;
      Log_P0    : constant Real := Log_R (1.0 - P);
      Log_P1    : constant Real := Log_R (P);
      Log_Ps    : Real;
      Log_Psp   : Real;
      Log_A     : Real;
      Accepted  : Natural := 0;
      Mom       : Moments;
      Stored_N  : Store_Count := 0;
      Samples_B : Sample_Array (1 .. Max_Store) := [others => 0.0];
      R         : Result;
      Keep_From : Natural;
      Xr        : Real;
   begin
      if P <= 0.0 or else P >= 1.0 then
         raise Invalid_Argument with "Bernoulli p must be in (0,1)";
      end if;
      if Cfg.Burn_In >= Cfg.Steps then
         raise Invalid_Argument with "Burn_In must be < Steps";
      end if;

      FR.Reset (Gen, Cfg.Seed);
      if Cfg.Start >= 0.5 then
         S := 1;
      else
         S := 0;
      end if;
      if S = 0 then
         Log_Ps := Log_P0;
      else
         Log_Ps := Log_P1;
      end if;
      Keep_From := Cfg.Burn_In + 1;

      for T in 1 .. Cfg.Steps loop
         Sp := 1 - S;  -- flip proposal (symmetric)
         if Sp = 0 then
            Log_Psp := Log_P0;
         else
            Log_Psp := Log_P1;
         end if;
         Log_A := Log_Hastings_Ratio (Log_Ps, Log_Psp, 0.0);

         if Unit_Open (Gen) <= Accept_Probability (Log_A) then
            S := Sp;
            Log_Ps := Log_Psp;
            Accepted := Accepted + 1;
         end if;

         if T >= Keep_From then
            Xr := Real (S);
            Push (Mom, Xr);
            if Cfg.Keep_Samples and then Stored_N < Max_Store then
               Stored_N := Stored_N + 1;
               Samples_B (Stored_N) := Xr;
            end if;
         end if;
      end loop;

      R := Finish (Mom, Accepted, Cfg.Steps);
      R.Stored := Stored_N;
      if Stored_N > 0 then
         R.Samples (1 .. Stored_N) := Samples_B (1 .. Stored_N);
      end if;
      return R;
   end Sample_Bernoulli;

   -------------------------------------------------------------------------
   -- Tiny 1D Ising Metropolis
   -------------------------------------------------------------------------

   function Sample_Ising_1D
     (N     : Positive;
      Beta  : Non_Negative;
      Steps : Positive := 20_000;
      Burn  : Natural  := 2_000;
      Seed  : Integer  := 42) return Ising_Result
   is
      type Spin_Arr is array (Positive range <>) of Integer;
      Gen       : FR.Generator;
      Spins     : Spin_Arr (1 .. N) := [others => 1];
      Accepted  : Natural := 0;
      Keep_From : Natural;
      R         : Ising_Result;
      Mag_Mom   : Moments;
      Eng_Mom   : Moments;
      I         : Positive;
      Old       : Integer;
      Diff_E   : Real;
      Mag       : Real;
      Eng       : Real;
      U         : Real;
      Idx       : Natural;
      Left      : Positive;
      Right     : Positive;

      function Energy return Real is
         E  : Real := 0.0;
         Rr : Positive;
      begin
         for K in 1 .. N loop
            Rr := (if K = N then 1 else K + 1);
            E := E - Real (Spins (K) * Spins (Rr));
         end loop;
         return E;
      end Energy;

      function Magnetization return Real is
         M : Real := 0.0;
      begin
         for K in 1 .. N loop
            M := M + Real (Spins (K));
         end loop;
         return M / Real (N);
      end Magnetization;

   begin
      if N < 2 or else N > Max_Ising_N then
         raise Invalid_Argument with "Ising N out of range";
      end if;
      if Burn >= Steps then
         raise Invalid_Argument with "Burn must be < Steps";
      end if;

      FR.Reset (Gen, Seed);
      --  Random initial spins
      for K in 1 .. N loop
         if Unit_Open (Gen) < 0.5 then
            Spins (K) := -1;
         else
            Spins (K) := 1;
         end if;
      end loop;

      Keep_From := Burn + 1;
      Eng := Energy;
      Mag := Magnetization;

      for T in 1 .. Steps loop
         --  Propose random site flip
         U := Unit_Open (Gen);
         Idx := Natural (U * Real (N));
         if Idx >= N then
            Idx := N - 1;
         end if;
         I := Idx + 1;
         Old := Spins (I);
         Left := (if I = 1 then N else I - 1);
         Right := (if I = N then 1 else I + 1);
         --  ΔE = 2 s_i (s_{i-1} + s_{i+1}) for J=1, h=0
         Diff_E :=
           2.0 * Real (Old) * Real (Spins (Left) + Spins (Right));

         if Unit_Open (Gen)
           <= Accept_Probability (-Beta * Diff_E)
         then
            Spins (I) := -Old;
            Eng := Eng + Diff_E;
            Mag := Mag + 2.0 * Real (Spins (I)) / Real (N);
            Accepted := Accepted + 1;
         end if;

         if T >= Keep_From then
            Push (Mag_Mom, Mag);
            Push (Eng_Mom, Eng);
         end if;
      end loop;

      R.Mean_Magnetization := Mag_Mom.Mean;
      R.Mean_Energy := Eng_Mom.Mean;
      R.N_Kept := Mag_Mom.N;
      R.Accept_Rate :=
        Unit_Fraction (Real (Accepted) / Real (Steps));
      return R;
   end Sample_Ising_1D;

   function Target_Iso_Normal_ND (X : Point) return Real is
      S : Real := 0.0;
   begin
      for I in X'Range loop
         S := S + X (I) * X (I);
      end loop;
      return -0.5 * S;
   end Target_Iso_Normal_ND;

   function Target_Std_Normal_ND (X : Point) return Real is
   begin
      return Target_Iso_Normal_ND (X);
   end Target_Std_Normal_ND;


end Metropolis_Hastings;
