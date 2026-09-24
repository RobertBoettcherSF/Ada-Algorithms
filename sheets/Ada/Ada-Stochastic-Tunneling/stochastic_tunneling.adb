--  Stochastic_Tunneling body — STUN transform, Metropolis accept, 1-D walk.

pragma Ada_2022;

with Ada.Numerics;
with Ada.Numerics.Generic_Elementary_Functions;

package body Stochastic_Tunneling
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
      --  Box–Muller; reject U1 = 0 to keep Log defined.
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
   -- STUN transform / Metropolis
   ---------------------------------------------------------------------------

   function Stun_Transform
     (E, E0 : Real; Gamma : Positive_Real) return Non_Negative
   is
      Diff : Real;
      Arg  : Real;
   begin
      if E <= E0 then
         --  Clamp: energies below the best-so-far map to the floor 0.
         return 0.0;
      end if;
      Diff := (E - E0) / Gamma;
      --  Cap argument to avoid Exp underflow noise for huge Diff.
      if Diff > 80.0 then
         return 1.0;
      end if;
      Arg := Exp (-Diff);
      return Non_Negative (1.0 - Arg);
   end Stun_Transform;

   function Metropolis_Accept_Prob
     (Delta_F_Stun : Real; Beta : Non_Negative) return Unit_Interval
   is
      Arg : Real;
   begin
      if Delta_F_Stun <= 0.0 then
         return 1.0;
      end if;
      if Beta = 0.0 then
         return 1.0;
      end if;
      Arg := Beta * Delta_F_Stun;
      if Arg > 80.0 then
         return 0.0;
      end if;
      return Unit_Interval (Exp (-Arg));
   end Metropolis_Accept_Prob;

   function Metropolis_Accept_Stun
     (Delta_F_Stun : Real;
      Beta         : Non_Negative;
      State        : in out RNG_State) return Boolean
   is
      P : constant Unit_Interval :=
        Metropolis_Accept_Prob (Delta_F_Stun, Beta);
      U : constant Unit_Interval := Next_Unit (State);
   begin
      return U < P;
   end Metropolis_Accept_Stun;

   function Metropolis_Accept_Energy
     (Delta_E : Real;
      Beta    : Non_Negative;
      State   : in out RNG_State) return Boolean
   is
   begin
      --  Same Metropolis rule on raw energy difference.
      return Metropolis_Accept_Stun (Delta_E, Beta, State);
   end Metropolis_Accept_Energy;

   ---------------------------------------------------------------------------
   -- Built-in objectives
   ---------------------------------------------------------------------------

   function Double_Well (X : Real) return Real is
      X2 : constant Real := X * X;
   begin
      --  Symmetric wells at ±1, linear tilt → deeper well near −1.
      return (X2 - 1.0) * (X2 - 1.0) + 0.15 * X;
   end Double_Well;

   function Rastrigin_1D (X : Real) return Real is
   begin
      return X * X - 10.0 * Cos (Two_Pi * X) + 10.0;
   end Rastrigin_1D;

   function Sum_Of_Gaussians (X : Real) return Real is
      function G (Mu, Sig, Amp : Real) return Real is
         D : constant Real := (X - Mu) / Sig;
      begin
         return -Amp * Exp (-0.5 * D * D);
      end G;
   begin
      --  Three wells; deepest (Amp=1.2) at x = −2.
      return G (-2.0, 0.4, 1.2) + G (0.0, 0.35, 0.7) + G (2.0, 0.45, 0.9);
   end Sum_Of_Gaussians;

   function Quadratic (X : Real) return Real is
   begin
      return X * X;
   end Quadratic;

   function Shifted_Quadratic (X : Real) return Real is
      D : constant Real := X - 3.0;
   begin
      return D * D;
   end Shifted_Quadratic;

   function Tall_Double_Well (X : Real) return Real is
      X2 : constant Real := X * X;
   begin
      return 25.0 * (X2 - 1.0) * (X2 - 1.0) + 0.2 * X;
   end Tall_Double_Well;

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
   -- STUN 1-D minimizer
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
      E0     : Real;
      Best_X : Real;
      F_Cur  : Non_Negative;
      F_New  : Non_Negative;
      Delta_F : Real;
      Acc    : Boolean;
      R      : Result;
   begin
      if Objective = null then
         raise Invalid_Argument with "Minimize_1D: null Objective";
      end if;
      if Lo >= Hi then
         raise Invalid_Argument with "Minimize_1D: Lo >= Hi";
      end if;

      Seed_RNG (State, Seed);
      X      := Clamp (X0, Lo, Hi);
      E      := Objective (X);
      E0     := E;
      Best_X := X;

      for Iter in 1 .. Cfg.Max_Iters loop
         Xp := Propose (X, Cfg, State, Lo, Hi);
         Ep := Objective (Xp);

         --  Update best-so-far before computing transforms so a new
         --  record immediately redefines the tunneling floor.
         if Ep < E0 then
            E0     := Ep;
            Best_X := Xp;
         end if;

         F_Cur   := Stun_Transform (E, E0, Cfg.Gamma);
         F_New   := Stun_Transform (Ep, E0, Cfg.Gamma);
         Delta_F := Real (F_New) - Real (F_Cur);
         Acc     := Metropolis_Accept_Stun (Delta_F, Cfg.Beta, State);

         if Acc then
            X := Xp;
            E := Ep;
         end if;

         R.Iters := Iter;
      end loop;

      R.Best_X := Best_X;
      R.Best_E := E0;
      return R;
   end Minimize_1D;

   ---------------------------------------------------------------------------
   -- Plain Metropolis 1-D (comparison)
   ---------------------------------------------------------------------------

   function Minimize_1D_Metropolis
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
      E0     : Real;
      Best_X : Real;
      Acc    : Boolean;
      R      : Result;
   begin
      if Objective = null then
         raise Invalid_Argument with "Minimize_1D_Metropolis: null Objective";
      end if;
      if Lo >= Hi then
         raise Invalid_Argument with "Minimize_1D_Metropolis: Lo >= Hi";
      end if;

      Seed_RNG (State, Seed);
      X      := Clamp (X0, Lo, Hi);
      E      := Objective (X);
      E0     := E;
      Best_X := X;

      for Iter in 1 .. Cfg.Max_Iters loop
         Xp := Propose (X, Cfg, State, Lo, Hi);
         Ep := Objective (Xp);

         Acc := Metropolis_Accept_Energy (Ep - E, Cfg.Beta, State);
         if Acc then
            X := Xp;
            E := Ep;
         end if;

         if E < E0 then
            E0     := E;
            Best_X := X;
         end if;

         R.Iters := Iter;
      end loop;

      R.Best_X := Best_X;
      R.Best_E := E0;
      return R;
   end Minimize_1D_Metropolis;

end Stochastic_Tunneling;
