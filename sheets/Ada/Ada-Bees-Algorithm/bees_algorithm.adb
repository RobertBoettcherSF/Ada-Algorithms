--  Bees_Algorithm body — Pham et al. (2005) educational continuous BA:
--  Init_Colony, Rank_Colony, Patch_Search, Step, Minimize_Box.

pragma Ada_2022;

package body Bees_Algorithm
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
     (N              : Scout_Count   := 20;
      M              : Site_Count    := 5;
      E              : Site_Count    := 2;
      Nep            : Forager_Count := 10;
      Nsp            : Forager_Count := 5;
      Ngh            : Non_Negative  := 0.5;
      Max_Iterations : Natural       := 500;
      Seed           : Natural       := 1) return Config
   is
   begin
      return
        (N              => N,
         M              => M,
         E              => E,
         Nep            => Nep,
         Nsp            => Nsp,
         Ngh            => Ngh,
         Max_Iterations => Max_Iterations,
         Seed           => Seed);
   end Default_Config;

   function Config_Is_Valid (Cfg : Config) return Boolean is
   begin
      return Natural (Cfg.E) <= Natural (Cfg.M)
        and then Natural (Cfg.M) <= Natural (Cfg.N);
   end Config_Is_Valid;

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

   procedure Random_Bee
     (Bee_Out   : out Bee;
      Dim       : Dim_Count;
      B         : Bounds;
      Objective : Objective_Fn;
      State     : in out RNG_State)
   is
      Bd : Bound;
   begin
      Bee_Out.Dim  := Dim;
      Bee_Out.X    := [others => 0.0];
      for D in 1 .. Dim loop
         Bd := Bound_At (B, D);
         Bee_Out.X (D) := Next_Uniform (State, Bd.Lo, Bd.Hi);
      end loop;
      Bee_Out.Cost := Objective (Slice_Point (Bee_Out.X, Dim));
   end Random_Bee;

   ---------------------------------------------------------------------------
   -- Colony core
   ---------------------------------------------------------------------------

   procedure Init_Colony
     (C         : in out Colony;
      B         : Bounds;
      Objective : Objective_Fn;
      State     : in out RNG_State)
   is
      Dim : constant Dim_Count := Dim_Count (B'Length);
   begin
      if Objective = null then
         raise Invalid_Argument;
      end if;
      Validate_Bounds (B);
      C.Dim  := Dim;
      C.Size := 0;
      for K in 1 .. C.Capacity loop
         Random_Bee (C.Bees (K), Dim, B, Objective, State);
         C.Size := C.Size + 1;
      end loop;
   end Init_Colony;

   procedure Rank_Colony (C : in out Colony) is
      --  Insertion sort ascending by Cost (stable for equal costs).
      Key : Bee;
      J   : Natural;
   begin
      if C.Size < 1 then
         raise Invalid_Argument;
      end if;
      for I in 2 .. C.Size loop
         Key := C.Bees (I);
         J := I - 1;
         while J >= 1 and then C.Bees (J).Cost > Key.Cost loop
            C.Bees (J + 1) := C.Bees (J);
            J := J - 1;
         end loop;
         C.Bees (J + 1) := Key;
      end loop;
   end Rank_Colony;

   function Patch_Search
     (Center     : Bee;
      Ngh        : Non_Negative;
      N_Foragers : Forager_Count;
      B          : Bounds;
      Objective  : Objective_Fn;
      State      : in out RNG_State) return Bee
   is
      Dim    : constant Dim_Count := Center.Dim;
      Best   : Bee := Center;
      Cand   : Bee;
      Bd     : Bound;
      Lo_D   : Real;
      Hi_D   : Real;
      Cost   : Real;
   begin
      if Objective = null
        or else Natural (Dim) /= B'Length
      then
         raise Invalid_Argument;
      end if;
      Validate_Bounds (B);

      Cand.Dim := Dim;
      Cand.X   := [others => 0.0];

      for F in 1 .. Natural (N_Foragers) loop
         for D in 1 .. Dim loop
            Bd := Bound_At (B, D);
            Lo_D := Clamp (Center.X (D) - Real (Ngh), Bd.Lo, Bd.Hi);
            Hi_D := Clamp (Center.X (D) + Real (Ngh), Bd.Lo, Bd.Hi);
            if Lo_D > Hi_D then
               --  Degenerate after clamp: stay at clamped center.
               Cand.X (D) := Clamp (Center.X (D), Bd.Lo, Bd.Hi);
            else
               Cand.X (D) := Next_Uniform (State, Lo_D, Hi_D);
            end if;
         end loop;
         Cost := Objective (Slice_Point (Cand.X, Dim));
         Cand.Cost := Cost;
         if Cost < Best.Cost then
            Best := Cand;
         end if;
      end loop;

      return Best;
   end Patch_Search;

   procedure Step
     (C         : in out Colony;
      B         : Bounds;
      Cfg       : Config;
      Objective : Objective_Fn;
      State     : in out RNG_State)
   is
      Dim   : constant Dim_Count := C.Dim;
      Elite : Natural;
      Best_Sites : Natural;
      Improved : Bee;
   begin
      if C.Size < 1
        or else B'Length /= Natural (Dim)
        or else Objective = null
        or else not Config_Is_Valid (Cfg)
        or else Natural (Cfg.N) /= C.Size
      then
         raise Invalid_Argument;
      end if;
      Validate_Bounds (B);

      Rank_Colony (C);

      Elite := Natural (Cfg.E);
      Best_Sites := Natural (Cfg.M);

      --  Elite sites: Nep foragers each.
      for I in 1 .. Elite loop
         Improved :=
           Patch_Search
             (C.Bees (I), Cfg.Ngh, Cfg.Nep, B, Objective, State);
         if Improved.Cost < C.Bees (I).Cost then
            C.Bees (I) := Improved;
         end if;
      end loop;

      --  Remaining best sites: Nsp foragers each.
      for I in Elite + 1 .. Best_Sites loop
         Improved :=
           Patch_Search
             (C.Bees (I), Cfg.Ngh, Cfg.Nsp, B, Objective, State);
         if Improved.Cost < C.Bees (I).Cost then
            C.Bees (I) := Improved;
         end if;
      end loop;

      --  Global random search for remaining scouts (site abandonment /
      --  re-scout of non-selected positions).
      for I in Best_Sites + 1 .. C.Size loop
         Random_Bee (C.Bees (I), Dim, B, Objective, State);
      end loop;
   end Step;

   function Best_Index (C : Colony) return Positive is
      Bi : Positive := 1;
   begin
      for K in 2 .. C.Size loop
         if C.Bees (K).Cost < C.Bees (Bi).Cost then
            Bi := K;
         end if;
      end loop;
      return Bi;
   end Best_Index;

   ---------------------------------------------------------------------------
   -- Drivers
   ---------------------------------------------------------------------------

   function Minimize_Box
     (Objective : Objective_Fn;
      B         : Bounds;
      Cfg       : Config) return Result
   is
      Dim   : constant Dim_Count := Dim_Count (B'Length);
      C     : Colony (Cfg.N);
      State : RNG_State;
      R     : Result;
      Bi    : Positive;
   begin
      if Objective = null or else not Config_Is_Valid (Cfg) then
         raise Invalid_Argument;
      end if;
      Validate_Bounds (B);
      Seed_RNG (State, Cfg.Seed);
      Init_Colony (C, B, Objective, State);

      Bi := Best_Index (C);
      R.Best_Cost := C.Bees (Bi).Cost;
      R.Best_X    := C.Bees (Bi).X;

      for Iter in 1 .. Cfg.Max_Iterations loop
         Step (C, B, Cfg, Objective, State);
         Bi := Best_Index (C);
         if C.Bees (Bi).Cost < R.Best_Cost then
            R.Best_Cost := C.Bees (Bi).Cost;
            R.Best_X    := C.Bees (Bi).X;
         end if;
      end loop;

      R.Dim         := Dim;
      R.Iterations  := Cfg.Max_Iterations;
      R.Scouts_Used := C.Size;
      return R;
   end Minimize_Box;

end Bees_Algorithm;
