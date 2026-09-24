--  Hybrid_Monte_Carlo package body — HMC sampling (leapfrog proposals,
--  Metropolis accept/reject on Hamiltonian, momentum refresh).

pragma Ada_2022;

with Ada.Numerics;
with Ada.Numerics.Elementary_Functions;
with Ada.Numerics.Float_Random;

package body Hybrid_Monte_Carlo is

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
   -- Kinetic / Hamiltonian / accept
   -------------------------------------------------------------------------

   function Kinetic_1D (P : Real) return Non_Negative is
   begin
      return Non_Negative (0.5 * P * P);
   end Kinetic_1D;

   function Kinetic_ND (P : Point) return Non_Negative is
      S : Real := 0.0;
   begin
      for I in P'Range loop
         S := S + P (I) * P (I);
      end loop;
      return Non_Negative (0.5 * S);
   end Kinetic_ND;

   function Hamiltonian_1D (U_Q, P : Real) return Real is
   begin
      return U_Q + Real (Kinetic_1D (P));
   end Hamiltonian_1D;

   function Hamiltonian_ND (U_Q : Real; P : Point) return Real is
   begin
      return U_Q + Real (Kinetic_ND (P));
   end Hamiltonian_ND;

   function Accept_Probability (Delta_H : Real) return Unit_Fraction is
      --  α = min(1, exp(−ΔH))
      Neg : constant Real := -Delta_H;
   begin
      if Neg >= 0.0 then
         return 1.0;
      else
         return Unit_Fraction (Exp_R (Neg));
      end if;
   end Accept_Probability;

   -------------------------------------------------------------------------
   -- Leapfrog (unit mass)
   -------------------------------------------------------------------------

   procedure Leapfrog_Step_1D
     (Q       : in out Real;
      P       : in out Real;
      Grad_U  : Gradient_1D;
      Epsilon : Positive_Real)
   is
      Half : constant Real := 0.5 * Epsilon;
   begin
      if Grad_U = null then
         raise Invalid_Argument with "Grad_U is null";
      end if;
      --  half kick
      P := P - Half * Grad_U (Q);
      --  full drift
      Q := Q + Epsilon * P;
      --  half kick
      P := P - Half * Grad_U (Q);
   end Leapfrog_Step_1D;

   procedure Leapfrog_1D
     (Q       : in out Real;
      P       : in out Real;
      Grad_U  : Gradient_1D;
      Epsilon : Positive_Real;
      L       : Leapfrog_Steps)
   is
   begin
      if Grad_U = null then
         raise Invalid_Argument with "Grad_U is null";
      end if;
      for Step in 1 .. L loop
         Leapfrog_Step_1D (Q, P, Grad_U, Epsilon);
      end loop;
   end Leapfrog_1D;

   procedure Leapfrog_Step_ND
     (Q       : in out Point;
      P       : in out Point;
      Grad_U  : Gradient_ND;
      Epsilon : Positive_Real)
   is
      Half : constant Real := 0.5 * Epsilon;
      G    : Point (Q'Range);
   begin
      if Grad_U = null then
         raise Invalid_Argument with "Grad_U is null";
      end if;

      G := Grad_U (Q);

      for I in Q'Range loop
         P (I) := P (I) - Half * G (I);
      end loop;

      for I in Q'Range loop
         Q (I) := Q (I) + Epsilon * P (I);
      end loop;

      G := Grad_U (Q);
      for I in Q'Range loop
         P (I) := P (I) - Half * G (I);
      end loop;
   end Leapfrog_Step_ND;

   procedure Leapfrog_ND
     (Q       : in out Point;
      P       : in out Point;
      Grad_U  : Gradient_ND;
      Epsilon : Positive_Real;
      L       : Leapfrog_Steps)
   is
   begin
      if Grad_U = null then
         raise Invalid_Argument with "Grad_U is null";
      end if;
      for Step in 1 .. L loop
         Leapfrog_Step_ND (Q, P, Grad_U, Epsilon);
      end loop;
   end Leapfrog_ND;

   -------------------------------------------------------------------------
   -- Educational potentials / gradients
   -------------------------------------------------------------------------

   function U_Std_Normal (Q : Real) return Real is
   begin
      return 0.5 * Q * Q;
   end U_Std_Normal;

   function Grad_U_Std_Normal (Q : Real) return Real is
   begin
      return Q;
   end Grad_U_Std_Normal;

   function U_Normal_Mu2 (Q : Real) return Real is
      D : constant Real := Q - 2.0;
   begin
      return 0.5 * D * D;
   end U_Normal_Mu2;

   function Grad_U_Normal_Mu2 (Q : Real) return Real is
   begin
      return Q - 2.0;
   end Grad_U_Normal_Mu2;

   function U_Normal_Wide (Q : Real) return Real is
      --  σ = 2 ⇒ σ² = 4
   begin
      return 0.5 * Q * Q / 4.0;
   end U_Normal_Wide;

   function Grad_U_Normal_Wide (Q : Real) return Real is
   begin
      return Q / 4.0;
   end Grad_U_Normal_Wide;

   function U_Iso_Normal_ND (Q : Point) return Real is
      S : Real := 0.0;
   begin
      for I in Q'Range loop
         S := S + Q (I) * Q (I);
      end loop;
      return 0.5 * S;
   end U_Iso_Normal_ND;

   function Grad_U_Iso_Normal_ND (Q : Point) return Point is
      G : Point (Q'Range);
   begin
      for I in Q'Range loop
         G (I) := Q (I);
      end loop;
      return G;
   end Grad_U_Iso_Normal_ND;

   -------------------------------------------------------------------------
   -- 1D HMC
   -------------------------------------------------------------------------

   function Sample_1D
     (U      : Potential_1D;
      Grad_U : Gradient_1D;
      Cfg    : Config := (others => <>)) return Result
   is
      Gen       : FR.Generator;
      Q         : Real := Cfg.Start;
      P         : Real;
      Q_Prop    : Real;
      P_Prop    : Real;
      H_Curr    : Real;
      H_Prop    : Real;
      Delta_H   : Real;
      Accepted  : Natural := 0;
      Mom       : Moments;
      Stored_N  : Store_Count := 0;
      Samples_B : Sample_Array (1 .. Max_Store) := [others => 0.0];
      R         : Result;
      Keep_From : Natural;
   begin
      if U = null or else Grad_U = null then
         raise Invalid_Argument with "U or Grad_U is null";
      end if;
      if Cfg.Burn_In >= Cfg.N_Samples then
         raise Invalid_Argument with "Burn_In must be < N_Samples";
      end if;

      FR.Reset (Gen, Cfg.Seed);
      Keep_From := Cfg.Burn_In + 1;

      for T in 1 .. Cfg.N_Samples loop
         --  Refresh momentum from N(0,1).
         P := Std_Normal (Gen);
         H_Curr := Hamiltonian_1D (U (Q), P);

         Q_Prop := Q;
         P_Prop := P;
         Leapfrog_1D (Q_Prop, P_Prop, Grad_U, Cfg.Epsilon, Cfg.L_Steps);

         --  Negate momentum for detailed balance (leapfrog is reversible;
         --  with K(p)=K(−p) this does not change H, but is conventional).
         P_Prop := -P_Prop;
         H_Prop := Hamiltonian_1D (U (Q_Prop), P_Prop);
         Delta_H := H_Prop - H_Curr;

         if Unit_Open (Gen) <= Accept_Probability (Delta_H) then
            Q := Q_Prop;
            Accepted := Accepted + 1;
         end if;

         if T >= Keep_From then
            Push (Mom, Q);
            if Cfg.Keep_Samples and then Stored_N < Max_Store then
               Stored_N := Stored_N + 1;
               Samples_B (Stored_N) := Q;
            end if;
         end if;
      end loop;

      R := Finish (Mom, Accepted, Cfg.N_Samples);
      R.Stored := Stored_N;
      if Stored_N > 0 then
         R.Samples (1 .. Stored_N) := Samples_B (1 .. Stored_N);
      end if;
      return R;
   end Sample_1D;

   -------------------------------------------------------------------------
   -- Multi-D HMC (D ≤ 4)
   -------------------------------------------------------------------------

   function Sample_ND
     (U      : Potential_ND;
      Grad_U : Gradient_ND;
      Cfg    : Config_ND) return Result_ND
   is
      Gen       : FR.Generator;
      Q         : Point (1 .. Cfg.D) := Cfg.Start;
      P         : Point (1 .. Cfg.D);
      Q_Prop    : Point (1 .. Cfg.D);
      P_Prop    : Point (1 .. Cfg.D);
      H_Curr    : Real;
      H_Prop    : Real;
      Delta_H   : Real;
      Accepted  : Natural := 0;
      Moms      : array (1 .. Cfg.D) of Moments;
      Keep_From : Natural;
      R         : Result_ND (Cfg.D);
   begin
      if U = null or else Grad_U = null then
         raise Invalid_Argument with "U or Grad_U is null";
      end if;
      if Cfg.Burn_In >= Cfg.N_Samples then
         raise Invalid_Argument with "Burn_In must be < N_Samples";
      end if;

      FR.Reset (Gen, Cfg.Seed);
      Keep_From := Cfg.Burn_In + 1;

      for T in 1 .. Cfg.N_Samples loop
         for I in 1 .. Cfg.D loop
            P (I) := Std_Normal (Gen);
         end loop;
         H_Curr := Hamiltonian_ND (U (Q), P);

         Q_Prop := Q;
         P_Prop := P;
         Leapfrog_ND (Q_Prop, P_Prop, Grad_U, Cfg.Epsilon, Cfg.L_Steps);

         for I in 1 .. Cfg.D loop
            P_Prop (I) := -P_Prop (I);
         end loop;
         H_Prop := Hamiltonian_ND (U (Q_Prop), P_Prop);
         Delta_H := H_Prop - H_Curr;

         if Unit_Open (Gen) <= Accept_Probability (Delta_H) then
            Q := Q_Prop;
            Accepted := Accepted + 1;
         end if;

         if T >= Keep_From then
            for I in 1 .. Cfg.D loop
               Push (Moms (I), Q (I));
            end loop;
         end if;
      end loop;

      for I in 1 .. Cfg.D loop
         R.Mean (I) := Moms (I).Mean;
         R.Variance (I) := Sample_Variance (Moms (I));
      end loop;
      R.N_Kept := Moms (1).N;
      R.N_Accepted := Accepted;
      R.N_Proposed := Cfg.N_Samples;
      R.Accept_Rate :=
        Unit_Fraction (Real (Accepted) / Real (Cfg.N_Samples));
      return R;
   end Sample_ND;

end Hybrid_Monte_Carlo;
