--  Particle_Swarm body — Kennedy & Eberhart (1995) educational PSO:
--  Init_Swarm, Step (inertia / cognitive / social), Minimize_Box.

pragma Ada_2022;

package body Particle_Swarm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Clamp (X, Lo, Hi : Real) return Real is
   begin
      if Lo > Hi then
         raise Invalid_Argument;
      end if;
      if X < Lo then
         return Lo;
      elsif X > Hi then
         return Hi;
      else
         return X;
      end if;
   end Clamp;

   function Default_Config
     (Swarm_Size     : Swarm_Count  := 20;
      Max_Iterations : Natural      := 500;
      Inertia        : Non_Negative := 0.729;
      C1             : Non_Negative := 1.49445;
      C2             : Non_Negative := 1.49445;
      Seed           : Natural      := 1) return Config
   is
   begin
      return
        (Swarm_Size     => Swarm_Size,
         Max_Iterations => Max_Iterations,
         Inertia        => Inertia,
         C1             => C1,
         C2             => C2,
         Seed           => Seed);
   end Default_Config;

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

   function Next_Uniform
     (State : in out RNG_State; Lo, Hi : Real) return Real
   is
      U : constant Unit_Interval := Next_Unit (State);
   begin
      return Lo + Real (U) * (Hi - Lo);
   end Next_Uniform;

   ---------------------------------------------------------------------------
   -- Objectives
   ---------------------------------------------------------------------------

   function Sphere (X : Point) return Real is
      S : Real := 0.0;
   begin
      for I in X'Range loop
         S := S + X (I) * X (I);
      end loop;
      return S;
   end Sphere;

   function Rosenbrock (X : Point) return Real is
      A  : constant Real := 1.0;
      B  : constant Real := 100.0;
      Xx : Real;
      Yy : Real;
   begin
      if X'Length < 2 then
         raise Invalid_Argument;
      end if;
      Xx := X (X'First);
      Yy := X (X'First + 1);
      return (A - Xx) ** 2 + B * (Yy - Xx ** 2) ** 2;
   end Rosenbrock;

   function Shifted_Sphere (X : Point) return Real is
      S : Real := 0.0;
   begin
      for I in X'Range loop
         S := S + (X (I) - 1.0) ** 2;
      end loop;
      return S;
   end Shifted_Sphere;

   ---------------------------------------------------------------------------
   -- Internal helpers
   ---------------------------------------------------------------------------

   procedure Validate_Bounds (B : Bounds) is
   begin
      for I in B'Range loop
         if B (I).Lo > B (I).Hi then
            raise Invalid_Argument;
         end if;
      end loop;
   end Validate_Bounds;

   function Slice_Point (P : Point; Dim : Dim_Count) return Point is
      Out_P : Point (1 .. Dim);
   begin
      for I in 1 .. Dim loop
         Out_P (I) := P (I);
      end loop;
      return Out_P;
   end Slice_Point;

   function Bound_At (B : Bounds; D : Dim_Count) return Bound is
   begin
      return B (B'First + D - 1);
   end Bound_At;

   ---------------------------------------------------------------------------
   -- Swarm core
   ---------------------------------------------------------------------------

   procedure Init_Swarm
     (S         : in out Swarm;
      B         : Bounds;
      Objective : Objective_Fn;
      State     : in out RNG_State)
   is
      Dim  : constant Dim_Count := Dim_Count (B'Length);
      Bd   : Bound;
      Span : Real;
      Cost : Real;
      First : Boolean := True;
   begin
      if Objective = null then
         raise Invalid_Argument;
      end if;
      Validate_Bounds (B);
      S.Dim    := Dim;
      S.Size   := 0;
      S.G      := [others => 0.0];
      S.G_Cost := Real'Last;

      for K in 1 .. S.Capacity loop
         S.Particles (K).Dim    := Dim;
         S.Particles (K).X      := [others => 0.0];
         S.Particles (K).V      := [others => 0.0];
         S.Particles (K).P      := [others => 0.0];
         S.Particles (K).P_Cost := Real'Last;

         for D in 1 .. Dim loop
            Bd := Bound_At (B, D);
            Span := abs (Bd.Hi - Bd.Lo);
            S.Particles (K).X (D) := Next_Uniform (State, Bd.Lo, Bd.Hi);
            S.Particles (K).V (D) := Next_Uniform (State, -Span, Span);
            S.Particles (K).P (D) := S.Particles (K).X (D);
         end loop;

         Cost := Objective (Slice_Point (S.Particles (K).X, Dim));
         S.Particles (K).P_Cost := Cost;
         S.Size := S.Size + 1;

         if First or else Cost < S.G_Cost then
            S.G_Cost := Cost;
            S.G := S.Particles (K).P;
            First := False;
         end if;
      end loop;
   end Init_Swarm;

   procedure Step
     (S         : in out Swarm;
      B         : Bounds;
      Cfg       : Config;
      Objective : Objective_Fn;
      State     : in out RNG_State)
   is
      Dim  : constant Dim_Count := S.Dim;
      Bd   : Bound;
      R1   : Unit_Interval;
      R2   : Unit_Interval;
      New_V : Real;
      New_X : Real;
      Cost  : Real;
   begin
      if S.Size < 1
        or else B'Length /= Natural (Dim)
        or else Objective = null
      then
         raise Invalid_Argument;
      end if;
      Validate_Bounds (B);

      for K in 1 .. S.Size loop
         for D in 1 .. Dim loop
            Bd := Bound_At (B, D);
            R1 := Next_Unit (State);
            R2 := Next_Unit (State);
            New_V :=
              Real (Cfg.Inertia) * S.Particles (K).V (D)
              + Real (Cfg.C1) * Real (R1)
                  * (S.Particles (K).P (D) - S.Particles (K).X (D))
              + Real (Cfg.C2) * Real (R2)
                  * (S.G (D) - S.Particles (K).X (D));
            New_X := S.Particles (K).X (D) + New_V;
            New_X := Clamp (New_X, Bd.Lo, Bd.Hi);
            S.Particles (K).V (D) := New_V;
            S.Particles (K).X (D) := New_X;
         end loop;

         Cost := Objective (Slice_Point (S.Particles (K).X, Dim));
         if Cost < S.Particles (K).P_Cost then
            S.Particles (K).P_Cost := Cost;
            for D in 1 .. Dim loop
               S.Particles (K).P (D) := S.Particles (K).X (D);
            end loop;
            if Cost < S.G_Cost then
               S.G_Cost := Cost;
               for D in 1 .. Dim loop
                  S.G (D) := S.Particles (K).X (D);
               end loop;
            end if;
         end if;
      end loop;
   end Step;

   function Best_Particle_Index (S : Swarm) return Positive is
      Bi : Positive := 1;
   begin
      for K in 2 .. S.Size loop
         if S.Particles (K).P_Cost < S.Particles (Bi).P_Cost then
            Bi := K;
         end if;
      end loop;
      return Bi;
   end Best_Particle_Index;

   ---------------------------------------------------------------------------
   -- Drivers
   ---------------------------------------------------------------------------

   function Minimize_Box
     (Objective : Objective_Fn;
      B         : Bounds;
      Cfg       : Config) return Result
   is
      Dim   : constant Dim_Count := Dim_Count (B'Length);
      S     : Swarm (Cfg.Swarm_Size);
      State : RNG_State;
      R     : Result;
   begin
      if Objective = null then
         raise Invalid_Argument;
      end if;
      Validate_Bounds (B);
      Seed_RNG (State, Cfg.Seed);
      Init_Swarm (S, B, Objective, State);

      for Iter in 1 .. Cfg.Max_Iterations loop
         Step (S, B, Cfg, Objective, State);
      end loop;

      R.Best_Cost  := S.G_Cost;
      R.Best_X     := S.G;
      R.Dim        := Dim;
      R.Iterations := Cfg.Max_Iterations;
      R.Swarm_Used := S.Size;
      return R;
   end Minimize_Box;

end Particle_Swarm;
