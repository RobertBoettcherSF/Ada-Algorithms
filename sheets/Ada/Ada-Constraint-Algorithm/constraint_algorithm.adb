--  Constraint_Algorithm body — SHAKE / RATTLE MD distance constraints.

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Constraint_Algorithm is

   package Math is new Ada.Numerics.Generic_Elementary_Functions (Real);

   Tiny : constant Real := 1.0E-30;

   -------------------------------------------------------------------------
   -- Config
   -------------------------------------------------------------------------

   function Default_Config return Solver_Config is
   begin
      return (Tol => 1.0E-10, Max_Iters => 500, Use_Reference => True);
   end Default_Config;

   -------------------------------------------------------------------------
   -- Numeric / vector helpers
   -------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Vec_Add (A, B : Vec3) return Vec3 is
   begin
      return (A.X + B.X, A.Y + B.Y, A.Z + B.Z);
   end Vec_Add;

   function Vec_Sub (A, B : Vec3) return Vec3 is
   begin
      return (A.X - B.X, A.Y - B.Y, A.Z - B.Z);
   end Vec_Sub;

   function Vec_Scale (V : Vec3; S : Real) return Vec3 is
   begin
      return (V.X * S, V.Y * S, V.Z * S);
   end Vec_Scale;

   function Dot (A, B : Vec3) return Real is
   begin
      return A.X * B.X + A.Y * B.Y + A.Z * B.Z;
   end Dot;

   function Norm2 (V : Vec3) return Non_Negative is
   begin
      return Non_Negative (Dot (V, V));
   end Norm2;

   function Norm (V : Vec3) return Non_Negative is
      N2 : constant Real := Dot (V, V);
   begin
      if N2 <= Tiny then
         return 0.0;
      end if;
      return Non_Negative (Math.Sqrt (N2));
   end Norm;

   function Distance (A, B : Vec3) return Non_Negative is
   begin
      return Norm (Vec_Sub (A, B));
   end Distance;

   function Bond_Length
     (Particles : Particle_Array;
      C         : Distance_Constraint) return Non_Negative
   is
   begin
      return Distance (Particles (C.I).Pos, Particles (C.J).Pos);
   end Bond_Length;

   -------------------------------------------------------------------------
   -- Constraint evaluation
   -------------------------------------------------------------------------

   function Constraint_Value
     (Particles : Particle_Array;
      C         : Distance_Constraint) return Real
   is
      R : constant Vec3 := Vec_Sub (Particles (C.I).Pos, Particles (C.J).Pos);
   begin
      return Dot (R, R) - Real (C.D) * Real (C.D);
   end Constraint_Value;

   function Constraint_Dot
     (Particles : Particle_Array;
      C         : Distance_Constraint) return Real
   is
      R : constant Vec3 := Vec_Sub (Particles (C.I).Pos, Particles (C.J).Pos);
      V : constant Vec3 := Vec_Sub (Particles (C.I).Vel, Particles (C.J).Vel);
   begin
      return Dot (R, V);
   end Constraint_Dot;

   function Constraint_Violation_Max
     (Particles   : Particle_Array;
      Constraints : Constraint_Array;
      N_Part      : Particle_Count;
      N_Cons      : Constraint_Count) return Non_Negative
   is
      pragma Unreferenced (N_Part);
      Max_Abs : Real := 0.0;
      G       : Real;
   begin
      for K in 1 .. N_Cons loop
         G := abs (Constraint_Value (Particles, Constraints (K)));
         if G > Max_Abs then
            Max_Abs := G;
         end if;
      end loop;
      return Non_Negative (Max_Abs);
   end Constraint_Violation_Max;

   function Velocity_Violation_Max
     (Particles   : Particle_Array;
      Constraints : Constraint_Array;
      N_Part      : Particle_Count;
      N_Cons      : Constraint_Count) return Non_Negative
   is
      pragma Unreferenced (N_Part);
      Max_Abs : Real := 0.0;
      Gd      : Real;
   begin
      for K in 1 .. N_Cons loop
         Gd := abs (Constraint_Dot (Particles, Constraints (K)));
         if Gd > Max_Abs then
            Max_Abs := Gd;
         end if;
      end loop;
      return Non_Negative (Max_Abs);
   end Velocity_Violation_Max;

   -------------------------------------------------------------------------
   -- Momentum
   -------------------------------------------------------------------------

   function Linear_Momentum
     (Particles : Particle_Array; N_Part : Particle_Count) return Vec3
   is
      P : Vec3 := (0.0, 0.0, 0.0);
   begin
      for I in 1 .. N_Part loop
         P := Vec_Add (P, Vec_Scale (Particles (I).Vel, Real (Particles (I).Mass)));
      end loop;
      return P;
   end Linear_Momentum;

   function Total_Mass
     (Particles : Particle_Array; N_Part : Particle_Count) return Non_Negative
   is
      M : Real := 0.0;
   begin
      for I in 1 .. N_Part loop
         M := M + Real (Particles (I).Mass);
      end loop;
      return Non_Negative (M);
   end Total_Mass;

   -------------------------------------------------------------------------
   -- SHAKE
   -------------------------------------------------------------------------
   --  Holonomic distance constraint:
   --    σ = |r_α - r_β|^2 - d^2 = 0.
   --  Absorbing (Δt)^2 into the multiplier, the classic Gauss–Seidel SHAKE
   --  update for one constraint is (reference bond vector r0 = r_α^0 - r_β^0):
   --    λ = σ / (2 r · r0 (1/m_α + 1/m_β)),
   --    r_α ← r_α - (λ / m_α) r0,
   --    r_β ← r_β + (λ / m_β) r0.
   --  Iterate over all constraints until max |σ| ≤ Tol.

   procedure Shake_Positions
     (Particles   : in out Particle_Array;
      Constraints : Constraint_Array;
      N_Part      : Particle_Count;
      N_Cons      : Constraint_Count;
      Config      : Solver_Config;
      Result      : out Shake_Result)
   is
      type Ref_Array is array (1 .. Max_Constraints) of Vec3;
      R0        : Ref_Array;
      Converged : Boolean := False;
      Iters     : Natural := 0;
      Max_G     : Real := 0.0;
   begin
      if N_Cons = 0 then
         Result := (True, 0, 0.0);
         return;
      end if;

      --  Validate indices / masses lightly
      for K in 1 .. N_Cons loop
         declare
            C : Distance_Constraint renames Constraints (K);
         begin
            if C.I > N_Part or else C.J > N_Part or else C.I = C.J then
               raise Invalid_Argument;
            end if;
         end;
      end loop;

      --  Snapshot reference bond vectors (unconstrained positions)
      for K in 1 .. N_Cons loop
         declare
            C : Distance_Constraint renames Constraints (K);
         begin
            R0 (K) := Vec_Sub (Particles (C.I).Pos, Particles (C.J).Pos);
         end;
      end loop;

      for Iter in 1 .. Config.Max_Iters loop
         Iters := Iter;
         Max_G := 0.0;

         for K in 1 .. N_Cons loop
            declare
               C     : Distance_Constraint renames Constraints (K);
               Ri    : Vec3 renames Particles (C.I).Pos;
               Rj    : Vec3 renames Particles (C.J).Pos;
               R     : constant Vec3 := Vec_Sub (Ri, Rj);
               Dir   : Vec3;
               Sigma : Real;
               Inv_M : Real;
               Denom : Real;
               Lambda : Real;
               Mi, Mj : Real;
            begin
               if Config.Use_Reference then
                  Dir := R0 (K);
               else
                  Dir := R;
               end if;

               Sigma := Dot (R, R) - Real (C.D) * Real (C.D);
               if abs (Sigma) > Max_G then
                  Max_G := abs (Sigma);
               end if;

               Mi := Real (Particles (C.I).Mass);
               Mj := Real (Particles (C.J).Mass);
               Inv_M := 1.0 / Mi + 1.0 / Mj;
               Denom := 2.0 * Dot (R, Dir) * Inv_M;

               if abs (Denom) > Tiny then
                  Lambda := Sigma / Denom;
                  Particles (C.I).Pos :=
                    Vec_Sub (Particles (C.I).Pos, Vec_Scale (Dir, Lambda / Mi));
                  Particles (C.J).Pos :=
                    Vec_Add (Particles (C.J).Pos, Vec_Scale (Dir, Lambda / Mj));
               end if;
            end;
         end loop;

         --  Recompute max violation after a full sweep
         Max_G := Real (Constraint_Violation_Max
           (Particles, Constraints, N_Part, N_Cons));

         if Max_G <= Real (Config.Tol) then
            Converged := True;
            exit;
         end if;
      end loop;

      Result :=
        (Converged   => Converged,
         Iterations  => Iters,
         Final_Max_G => Non_Negative (Max_G));
   end Shake_Positions;

   -------------------------------------------------------------------------
   -- RATTLE (velocity projection)
   -------------------------------------------------------------------------
   --  Differentiating σ = |r|^2 - d^2 gives
   --    σ_dot = 2 r · v_rel = 0  ⇒  r · (v_α - v_β) = 0.
   --  Lagrange correction (one constraint):
   --    μ = (r · v_rel) / (|r|^2 (1/m_α + 1/m_β)),
   --    v_α ← v_α - (μ / m_α) r,
   --    v_β ← v_β + (μ / m_β) r.

   procedure Rattle_Velocities
     (Particles   : in out Particle_Array;
      Constraints : Constraint_Array;
      N_Part      : Particle_Count;
      N_Cons      : Constraint_Count;
      Config      : Solver_Config;
      Result      : out Rattle_Result)
   is
      Converged : Boolean := False;
      Iters     : Natural := 0;
      Max_Gd    : Real := 0.0;
   begin
      if N_Cons = 0 then
         Result := (True, 0, 0.0);
         return;
      end if;

      for K in 1 .. N_Cons loop
         declare
            C : Distance_Constraint renames Constraints (K);
         begin
            if C.I > N_Part or else C.J > N_Part or else C.I = C.J then
               raise Invalid_Argument;
            end if;
         end;
      end loop;

      for Iter in 1 .. Config.Max_Iters loop
         Iters := Iter;

         for K in 1 .. N_Cons loop
            declare
               C     : Distance_Constraint renames Constraints (K);
               R     : constant Vec3 :=
                 Vec_Sub (Particles (C.I).Pos, Particles (C.J).Pos);
               Vrel  : constant Vec3 :=
                 Vec_Sub (Particles (C.I).Vel, Particles (C.J).Vel);
               R2    : constant Real := Dot (R, R);
               Gdot  : constant Real := Dot (R, Vrel);
               Mi, Mj : Real;
               Inv_M : Real;
               Denom : Real;
               Mu    : Real;
            begin
               Mi := Real (Particles (C.I).Mass);
               Mj := Real (Particles (C.J).Mass);
               Inv_M := 1.0 / Mi + 1.0 / Mj;
               Denom := R2 * Inv_M;
               if abs (Denom) > Tiny then
                  Mu := Gdot / Denom;
                  Particles (C.I).Vel :=
                    Vec_Sub (Particles (C.I).Vel, Vec_Scale (R, Mu / Mi));
                  Particles (C.J).Vel :=
                    Vec_Add (Particles (C.J).Vel, Vec_Scale (R, Mu / Mj));
               end if;
            end;
         end loop;

         Max_Gd := Real (Velocity_Violation_Max
           (Particles, Constraints, N_Part, N_Cons));

         if Max_Gd <= Real (Config.Tol) then
            Converged := True;
            exit;
         end if;
      end loop;

      Result :=
        (Converged      => Converged,
         Iterations     => Iters,
         Final_Max_GDot => Non_Negative (Max_Gd));
   end Rattle_Velocities;

   -------------------------------------------------------------------------
   -- Velocity-Verlet + SHAKE/RATTLE (a = 0 free flight)
   -------------------------------------------------------------------------

   procedure Velocity_Verlet_Constrained_Step
     (Particles   : in out Particle_Array;
      Constraints : Constraint_Array;
      N_Part      : Particle_Count;
      N_Cons      : Constraint_Count;
      Dt          : Positive_Real;
      Config      : Solver_Config;
      Result      : out Step_Result)
   is
      type Pos_Snap is array (1 .. Max_Particles) of Vec3;
      Old_Pos : Pos_Snap;
      Shake_R : Shake_Result;
      Rattle_R : Rattle_Result;
   begin
      if N_Part = 0 then
         raise Empty_System;
      end if;

      for I in 1 .. N_Part loop
         Old_Pos (I) := Particles (I).Pos;
         --  a = 0 ⇒ half-step velocity unchanged; full position update
         Particles (I).Pos :=
           Vec_Add (Particles (I).Pos, Vec_Scale (Particles (I).Vel, Real (Dt)));
      end loop;

      Shake_Positions
        (Particles, Constraints, N_Part, N_Cons, Config, Shake_R);

      --  Rebuild velocities consistent with the constrained displacement
      for I in 1 .. N_Part loop
         Particles (I).Vel :=
           Vec_Scale (Vec_Sub (Particles (I).Pos, Old_Pos (I)), 1.0 / Real (Dt));
      end loop;

      Rattle_Velocities
        (Particles, Constraints, N_Part, N_Cons, Config, Rattle_R);

      Result := (Shake => Shake_R, Rattle => Rattle_R);
   end Velocity_Verlet_Constrained_Step;

   -------------------------------------------------------------------------
   -- Demo builders
   -------------------------------------------------------------------------

   procedure Make_Diatomic
     (Mass_A, Mass_B : Positive_Real;
      Bond_Length    : Positive_Real;
      Particles      : out Particle_Array;
      N_Part         : out Particle_Count;
      Constraints    : out Constraint_Array;
      N_Cons         : out Constraint_Count)
   is
   begin
      Particles := [others => <>];
      Constraints := [others => <>];
      N_Part := 2;
      N_Cons := 1;
      Particles (1) :=
        (Mass => Mass_A,
         Pos  => (0.0, 0.0, 0.0),
         Vel  => (0.0, 0.0, 0.0));
      Particles (2) :=
        (Mass => Mass_B,
         Pos  => (Real (Bond_Length), 0.0, 0.0),
         Vel  => (0.0, 0.0, 0.0));
      Constraints (1) := (I => 1, J => 2, D => Bond_Length);
   end Make_Diatomic;

   procedure Make_Water_Like
     (Bond_OH, Bond_HH : Positive_Real;
      Particles        : out Particle_Array;
      N_Part           : out Particle_Count;
      Constraints      : out Constraint_Array;
      N_Cons           : out Constraint_Count)
   is
      --  Place O at origin; H1, H2 in xy-plane so |OH|=Bond_OH, |HH|=Bond_HH.
      Half_HH : constant Real := Real (Bond_HH) / 2.0;
      OH2     : constant Real := Real (Bond_OH) * Real (Bond_OH);
      Hx2     : constant Real := Half_HH * Half_HH;
      Z2      : Real;
      X_H     : Real;
   begin
      if Hx2 > OH2 then
         raise Invalid_Argument;
      end if;
      Z2 := OH2 - Hx2;
      X_H := Half_HH;
      --  Use y as the "height" of the isosceles triangle in the plane
      declare
         Y_H : constant Real := Math.Sqrt (Z2);
      begin
         Particles := [others => <>];
         Constraints := [others => <>];
         N_Part := 3;
         N_Cons := 3;
         --  Masses: O=16, H=1 (amu-like educational units)
         Particles (1) :=
           (Mass => 16.0, Pos => (0.0, 0.0, 0.0), Vel => (0.0, 0.0, 0.0));
         Particles (2) :=
           (Mass => 1.0, Pos => (X_H, Y_H, 0.0), Vel => (0.0, 0.0, 0.0));
         Particles (3) :=
           (Mass => 1.0, Pos => (-X_H, Y_H, 0.0), Vel => (0.0, 0.0, 0.0));
         Constraints (1) := (I => 1, J => 2, D => Bond_OH);  -- O-H1
         Constraints (2) := (I => 1, J => 3, D => Bond_OH);  -- O-H2
         Constraints (3) := (I => 2, J => 3, D => Bond_HH);  -- H-H
      end;
   end Make_Water_Like;

   procedure Make_Two_Bond_Chain
     (Bond_Length : Positive_Real;
      Particles   : out Particle_Array;
      N_Part      : out Particle_Count;
      Constraints : out Constraint_Array;
      N_Cons      : out Constraint_Count)
   is
      D : constant Real := Real (Bond_Length);
   begin
      Particles := [others => <>];
      Constraints := [others => <>];
      N_Part := 3;
      N_Cons := 2;
      Particles (1) :=
        (Mass => 1.0, Pos => (0.0, 0.0, 0.0), Vel => (0.0, 0.0, 0.0));
      Particles (2) :=
        (Mass => 1.0, Pos => (D, 0.0, 0.0), Vel => (0.0, 0.0, 0.0));
      Particles (3) :=
        (Mass => 1.0, Pos => (2.0 * D, 0.0, 0.0), Vel => (0.0, 0.0, 0.0));
      Constraints (1) := (I => 1, J => 2, D => Bond_Length);
      Constraints (2) := (I => 2, J => 3, D => Bond_Length);
   end Make_Two_Bond_Chain;

   -------------------------------------------------------------------------
   -- Deterministic perturbation RNG (LCG)
   -------------------------------------------------------------------------

   procedure Perturb_Positions
     (Particles : in out Particle_Array;
      N_Part    : Particle_Count;
      Scale     : Real;
      Seed      : Natural := 1)
   is
      type U32 is mod 2**32;
      State : U32 := U32 (if Seed = 0 then 1 else Seed);

      function Next_Unit return Real is
      begin
         State := State * 1_664_525 + 1_013_904_223;
         return Real (State rem 10_000) / 10_000.0;
      end Next_Unit;

      function Next_Signed return Real is
      begin
         return (Next_Unit * 2.0 - 1.0) * Scale;
      end Next_Signed;
   begin
      for I in 1 .. N_Part loop
         Particles (I).Pos.X := Particles (I).Pos.X + Next_Signed;
         Particles (I).Pos.Y := Particles (I).Pos.Y + Next_Signed;
         Particles (I).Pos.Z := Particles (I).Pos.Z + Next_Signed;
      end loop;
   end Perturb_Positions;

end Constraint_Algorithm;
