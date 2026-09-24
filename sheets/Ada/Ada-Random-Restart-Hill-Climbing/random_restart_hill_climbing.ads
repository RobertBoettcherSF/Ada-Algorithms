--  Random_Restart_Hill_Climbing — Ada 2023 educational package for
--  Wikipedia "Hill climbing" § Random-restart hill climbing (also known
--  as Shotgun hill climbing): repeatedly run local hill climbing from
--  random starts and keep the globally best local optimum found.
--  Primary source: https://en.wikipedia.org/wiki/Hill_climbing
--  (random-restart / shotgun section); redirect Random-restart_hill_climbing.
--  Siblings: Ada-Tabu-Search / Ada-Simulated-Annealing / Ada-Random-Search.

pragma Ada_2022;

package Random_Restart_Hill_Climbing
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Unit_Interval is Real range 0.0 .. 1.0;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   --  Max_Restarts    : number of random starts (0 → empty Result)
   --  Max_Climb_Steps : per-climb steepest-descent iteration budget
   --  Seed            : LCG seed for random starts / reproducibility
   --  Step            : continuous neighborhood half-width (±Step)
   type Config is record
      Max_Restarts    : Natural       := 20;
      Max_Climb_Steps : Positive      := 500;
      Seed            : Natural       := 1;
      Step            : Positive_Real := 0.1;
   end record;

   --  Aggregated stats shared by demos (domain payloads live in *Result).
   type Result is record
      Best_Cost     : Real    := 0.0;
      Restarts_Used : Natural := 0;
      Climbs        : Natural := 0;  -- total improving moves across climbs
   end record;

   type Objective_1D is access function (X : Real) return Real;

   ---------------------------------------------------------------------------
   -- Exceptions / helpers
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;

   Epsilon_Tol : constant Real := 1.0E-10;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Clamp (X, Lo, Hi : Real) return Real
     with Global => null;

   ---------------------------------------------------------------------------
   -- Seeded RNG (32-bit LCG) for reproducible random restarts
   ---------------------------------------------------------------------------

   type RNG_State is mod 2**32;

   procedure Seed_RNG (State : out RNG_State; Seed : Natural)
     with Global => null;

   function Next_Unit (State : in out RNG_State) return Unit_Interval
     with Global => null;
   --  Uniform on [0, 1).

   function Next_Uniform
     (State : in out RNG_State; Lo, Hi : Real) return Real
     with Pre => Lo <= Hi, Global => null;

   function Next_Natural
     (State : in out RNG_State; Lo, Hi : Natural) return Natural
     with Pre => Lo <= Hi, Global => null;

   ---------------------------------------------------------------------------
   -- Bit-string demos: OneMax (minimize zeros) / Hamming to target
   -- Neighborhood: single bit flip. Strategy: steepest descent.
   ---------------------------------------------------------------------------

   Max_Bits : constant := 32;
   subtype Bit_Count is Positive range 1 .. Max_Bits;
   type Bit_String is array (Positive range <>) of Boolean;

   type Bit_Result is record
      Best_Bits     : Bit_String (1 .. Max_Bits) := [others => False];
      N             : Bit_Count := 1;
      Best_Cost     : Real    := 0.0;
      Restarts_Used : Natural := 0;
      Climbs        : Natural := 0;
   end record;

   function Hamming_Distance (A, B : Bit_String) return Natural
     with Pre => A'Length = B'Length, Global => null;

   function Zero_Count (Bits : Bit_String) return Natural
     with Global => null;

   function Ones_Count (Bits : Bit_String) return Natural
     with Global => null;

   function Flip_Bit (Bits : Bit_String; Index : Positive) return Bit_String
     with Pre => Index in Bits'Range, Global => null;

   function Random_Bit_String
     (State : in out RNG_State; N : Bit_Count) return Bit_String
     with Global => null;

   --  Single steepest-descent climb from Start (bit-flip neighborhood).
   function Hill_Climb_Hamming
     (Start  : Bit_String;
      Target : Bit_String;
      Cfg    : Config) return Bit_Result
     with Pre => Start'Length = Target'Length
            and then Start'Length >= 1
            and then Start'Length <= Max_Bits,
          Global => null;

   function Hill_Climb_OneMax
     (Start : Bit_String; Cfg : Config) return Bit_Result
     with Pre => Start'Length >= 1 and then Start'Length <= Max_Bits,
          Global => null;

   --  Random-restart: many random starts; keep globally best local opt.
   function Random_Restart_Hamming
     (Target : Bit_String; Cfg : Config) return Bit_Result
     with Pre => Target'Length >= 1 and then Target'Length <= Max_Bits,
          Global => null;

   function Random_Restart_OneMax
     (N : Bit_Count; Cfg : Config) return Bit_Result
     with Global => null;

   ---------------------------------------------------------------------------
   -- Continuous 1-D: Sphere / Double_Well with ±Step neighborhood
   ---------------------------------------------------------------------------

   type Cont_Result is record
      Best_X        : Real    := 0.0;
      Best_Cost     : Real    := 0.0;
      Restarts_Used : Natural := 0;
      Climbs        : Natural := 0;
   end record;

   function Sphere_1D (X : Real) return Real
     with Global => null;
   --  f(x) = x²; unique min 0 at x = 0.

   function Shifted_Sphere_1D (X : Real) return Real
     with Global => null;
   --  f(x) = (x − 3)²; unique min 0 at x = 3.

   function Double_Well (X : Real) return Real
     with Global => null;
   --  f(x) = (x² − 1)² + 0.15·x
   --  Local min near x ≈ +1; deeper (global) min near x ≈ −1.

   function Two_Basin (X : Real) return Real
     with Global => null;
   --  Piecewise multimodal toy: shallow basin around +2, deep around −3.
   --  Single climb from +2 fails globally; restarts find −3.

   function Hill_Climb_1D
     (Objective : Objective_1D;
      X0        : Real;
      Cfg       : Config;
      Lo        : Real := -10.0;
      Hi        : Real := 10.0) return Cont_Result
     with Pre => Lo < Hi and then Objective /= null, Global => null;
   --  Steepest descent on neighbors {x−Step, x+Step} clamped to [Lo,Hi].
   --  Strict improvement only; stops at local opt or Max_Climb_Steps.

   function Random_Restart_1D
     (Objective : Objective_1D;
      Cfg       : Config;
      Lo        : Real := -10.0;
      Hi        : Real := 10.0) return Cont_Result
     with Pre => Lo < Hi and then Objective /= null, Global => null;

   ---------------------------------------------------------------------------
   -- Tiny TSP 2-opt hill climb + restarts (n ≤ 10)
   ---------------------------------------------------------------------------

   Max_Cities : constant := 10;
   subtype City_Count is Positive range 2 .. Max_Cities;
   type City_Index is range 1 .. Max_Cities;
   type Tour is array (City_Index range <>) of City_Index;
   type Dist_Matrix is
     array (City_Index range <>, City_Index range <>) of Non_Negative;

   type TSP_Result is record
      Best_Tour     : Tour (1 .. Max_Cities) := [others => 1];
      N             : City_Count := 2;
      Best_Length   : Non_Negative := 0.0;
      Restarts_Used : Natural := 0;
      Climbs        : Natural := 0;
   end record;

   function Tour_Length (T : Tour; D : Dist_Matrix) return Non_Negative
     with Pre => T'First = D'First (1)
            and then T'Last = D'Last (1)
            and then D'First (1) = D'First (2)
            and then D'Last (1) = D'Last (2),
          Global => null;

   function Apply_2Opt (T : Tour; I, J : City_Index) return Tour
     with Pre => I in T'Range
            and then J in T'Range
            and then I < J,
          Global => null;
   --  Reverse segment T(I+1 .. J).

   function Identity_Tour (N : City_Count) return Tour
     with Global => null;

   function Random_Tour
     (State : in out RNG_State; N : City_Count) return Tour
     with Global => null;

   function Hill_Climb_TSP
     (D     : Dist_Matrix;
      Start : Tour;
      Cfg   : Config) return TSP_Result
     with Pre => Start'First = D'First (1)
            and then Start'Last = D'Last (1)
            and then D'First (1) = D'First (2)
            and then D'Last (1) = D'Last (2)
            and then Start'Length >= 2
            and then Start'Length <= Max_Cities,
          Global => null;
   --  Steepest-descent 2-opt: move to best strictly shorter neighbor.

   function Random_Restart_TSP
     (D : Dist_Matrix; Cfg : Config) return TSP_Result
     with Pre => D'First (1) = D'First (2)
            and then D'Last (1) = D'Last (2)
            and then D'Length (1) >= 2
            and then D'Length (1) <= Max_Cities,
          Global => null;

   ---------------------------------------------------------------------------
   -- Convenience: pack domain Result into shared Result
   ---------------------------------------------------------------------------

   function To_Result (R : Bit_Result) return Result
     with Global => null;
   function To_Result (R : Cont_Result) return Result
     with Global => null;
   function To_Result (R : TSP_Result) return Result
     with Global => null;

end Random_Restart_Hill_Climbing;
