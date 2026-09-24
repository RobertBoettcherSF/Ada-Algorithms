--  Local_Search — Ada 2023 educational survey package for Wikipedia
--  "Local search (optimization)": candidate solutions, neighborhoods,
--  hill climbing (steepest / first-improvement), random-restart wrapper,
--  iterated local search sketch, and 2-opt for tiny TSP. Taxonomy flags
--  cover Tabu / Simulated_Annealing / Random_Search (metadata only —
--  see sibling repos). Self-contained; no package deps on siblings.
--  Primary source: https://en.wikipedia.org/wiki/Local_search_(optimization)
--  Educational limits: bits ≤ 32, cities ≤ 10.

pragma Ada_2022;

package Local_Search
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Unit_Interval is Real range 0.0 .. 1.0;

   --  Max_Climb_Steps : per-climb iteration budget
   --  Max_Restarts    : random-restart / ILS outer-loop budget
   --  Perturb_Flips   : ILS perturbation strength (bit flips)
   --  Seed            : LCG seed for reproducibility
   type Config is record
      Max_Climb_Steps : Positive := 500;
      Max_Restarts    : Natural  := 5;
      Perturb_Flips   : Positive := 2;
      Seed            : Natural  := 1;
   end record;

   --  Aggregated stats (domain payloads live in Bit_Result / TSP_Result).
   type Result is record
      Best_Cost     : Real    := 0.0;
      Restarts_Used : Natural := 0;
      Climbs        : Natural := 0;  -- improving moves
      Perturbations : Natural := 0;  -- ILS outer iterations
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions / numeric helpers
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;

   Epsilon_Tol : constant Real := 1.0E-10;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Default_Config
     (Max_Climb_Steps : Positive := 500;
      Max_Restarts    : Natural  := 5;
      Perturb_Flips   : Positive := 2;
      Seed            : Natural  := 1) return Config
     with Global => null;

   ---------------------------------------------------------------------------
   -- Seeded RNG (32-bit LCG) for reproducible restarts / perturbations
   ---------------------------------------------------------------------------

   type RNG_State is mod 2**32;

   procedure Seed_RNG (State : out RNG_State; Seed : Natural)
     with Global => null;

   function Next_Unit (State : in out RNG_State) return Unit_Interval
     with Global => null;
   --  Uniform on [0, 1).

   function Next_Natural
     (State : in out RNG_State; Lo, Hi : Natural) return Natural
     with Pre => Lo <= Hi, Global => null;

   ---------------------------------------------------------------------------
   -- Bit-string state helpers: OneMax (minimize zeros) / Hamming to target
   -- Neighborhood: single bit flip.
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
      Perturbations : Natural := 0;
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

   function Copy_Bits (Src : Bit_String; N : Bit_Count) return Bit_String
     with Pre => Src'Length >= N, Global => null;
   --  Return Src (1 .. N) when Src'First = 1; else first N elements.

   function All_Ones (N : Bit_Count) return Bit_String
     with Global => null;

   function All_Zeros (N : Bit_Count) return Bit_String
     with Global => null;

   function Is_Local_Optimum_Hamming
     (Bits : Bit_String; Target : Bit_String) return Boolean
     with Pre => Bits'Length = Target'Length
            and then Bits'Length >= 1
            and then Bits'Length <= Max_Bits,
          Global => null;
   --  True iff no single flip strictly reduces Hamming distance.

   function Is_Local_Optimum_OneMax (Bits : Bit_String) return Boolean
     with Pre => Bits'Length >= 1 and then Bits'Length <= Max_Bits,
          Global => null;
   --  True iff no single flip reduces Zero_Count (i.e. all ones, or stuck).

   ---------------------------------------------------------------------------
   -- Steepest hill climb (bit-flip): evaluate full neighborhood, take best
   ---------------------------------------------------------------------------

   function Steepest_Climb_Hamming
     (Start  : Bit_String;
      Target : Bit_String;
      Cfg    : Config) return Bit_Result
     with Pre => Start'Length = Target'Length
            and then Start'Length >= 1
            and then Start'Length <= Max_Bits,
          Global => null;

   function Steepest_Climb_OneMax
     (Start : Bit_String; Cfg : Config) return Bit_Result
     with Pre => Start'Length >= 1 and then Start'Length <= Max_Bits,
          Global => null;

   ---------------------------------------------------------------------------
   -- First-improvement hill climb: take first improving flip (scan order)
   ---------------------------------------------------------------------------

   function First_Improve_Hamming
     (Start  : Bit_String;
      Target : Bit_String;
      Cfg    : Config) return Bit_Result
     with Pre => Start'Length = Target'Length
            and then Start'Length >= 1
            and then Start'Length <= Max_Bits,
          Global => null;

   function First_Improve_OneMax
     (Start : Bit_String; Cfg : Config) return Bit_Result
     with Pre => Start'Length >= 1 and then Start'Length <= Max_Bits,
          Global => null;

   ---------------------------------------------------------------------------
   -- Random-restart wrapper: few random starts; keep globally best local opt
   ---------------------------------------------------------------------------

   function Random_Restart_Hamming
     (Target : Bit_String; Cfg : Config) return Bit_Result
     with Pre => Target'Length >= 1 and then Target'Length <= Max_Bits,
          Global => null;

   function Random_Restart_OneMax
     (N : Bit_Count; Cfg : Config) return Bit_Result
     with Global => null;

   ---------------------------------------------------------------------------
   -- Iterated local search sketch:
   --   climb → perturb (k random flips) → climb → accept if better
   ---------------------------------------------------------------------------

   function Iterated_Local_Search_Hamming
     (Start  : Bit_String;
      Target : Bit_String;
      Cfg    : Config) return Bit_Result
     with Pre => Start'Length = Target'Length
            and then Start'Length >= 1
            and then Start'Length <= Max_Bits,
          Global => null;

   function Iterated_Local_Search_OneMax
     (Start : Bit_String; Cfg : Config) return Bit_Result
     with Pre => Start'Length >= 1 and then Start'Length <= Max_Bits,
          Global => null;

   function Perturb_Bits
     (Bits  : Bit_String;
      State : in out RNG_State;
      K     : Positive) return Bit_String
     with Pre => Bits'Length >= 1 and then Bits'Length <= Max_Bits,
          Global => null;
   --  Flip K distinct-or-with-replacement random bits (with replacement OK).

   ---------------------------------------------------------------------------
   -- Tiny TSP 2-opt local search (n ≤ 10)
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
      Perturbations : Natural := 0;
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
   --  Reverse segment T(I+1 .. J). Classic 2-opt move.

   function Identity_Tour (N : City_Count) return Tour
     with Global => null;

   function Random_Tour
     (State : in out RNG_State; N : City_Count) return Tour
     with Global => null;

   function Is_Local_Optimum_TSP
     (T : Tour; D : Dist_Matrix) return Boolean
     with Pre => T'First = D'First (1)
            and then T'Last = D'Last (1)
            and then D'First (1) = D'First (2)
            and then D'Last (1) = D'Last (2)
            and then T'Length >= 2
            and then T'Length <= Max_Cities,
          Global => null;
   --  True iff no 2-opt move strictly shortens the tour.

   function Two_Opt_Local_Search
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
   -- Taxonomy (method metadata; Tabu / SA / Random_Search = flags only)
   ---------------------------------------------------------------------------

   type Method_Kind is
     (Hill_Climbing,
      Random_Restart,
      Tabu,
      Simulated_Annealing,
      Iterated_Local_Search,
      Random_Search);

   type Method_Info is record
      Kind        : Method_Kind;
      Implemented : Boolean;
      Stochastic  : Boolean;
      Uses_Memory : Boolean;  -- e.g. tabu list
   end record;

   function Classify_Method (Kind : Method_Kind) return Method_Info
     with Global => null;

   function Method_Name (Kind : Method_Kind) return String
     with Global => null;

   function Method_Implemented (Kind : Method_Kind) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- Convenience: pack domain results into shared Result
   ---------------------------------------------------------------------------

   function To_Result (R : Bit_Result) return Result
     with Global => null;

   function To_Result (R : TSP_Result) return Result
     with Global => null;

end Local_Search;
