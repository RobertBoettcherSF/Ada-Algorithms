--  Memetic_Algorithm — Ada 2023 educational package for Wikipedia
--  "Memetic algorithm" (Moscato 1989): hybrid evolutionary algorithm
--  (population EA) plus individual local search / learning. This package
--  implements a Lamarckian educational MA: tournament selection,
--  one-point (bits) / order (TSP) crossover, mutation, then steepest or
--  first-improvement hill climb on offspring (chromosome updated).
--  Primary source: https://en.wikipedia.org/wiki/Memetic_algorithm
--  Siblings: Ada-Local-Search / Ada-Tabu-Search /
--  Ada-Random-Restart-Hill-Climbing (README links; no package deps).

pragma Ada_2022;

package Memetic_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Unit_Interval is Real range 0.0 .. 1.0;

   Max_Bits   : constant := 32;
   Max_Cities : constant := 10;
   Max_Pop    : constant := 64;

   subtype Bit_Count is Positive range 1 .. Max_Bits;
   subtype City_Count is Positive range 2 .. Max_Cities;
   subtype Pop_Size_T is Positive range 2 .. Max_Pop;
   subtype Tourney_K is Positive range 2 .. Max_Pop;

   --  Pop_Size           : population size
   --  Generations        : outer EA generations (0 → init-only Result)
   --  Mutation_Rate      : per-locus bit-flip / per-swap tour mutation P
   --  Local_Search_Steps : max hill-climb improving steps per improve
   --  Tournament_Size    : k-tournament selection
   --  Seed               : LCG seed for reproducibility
   --  Use_Steepest       : True = steepest; False = first-improvement
   --  Improve_All        : True = LS on all offspring; False = elites only
   type Config is record
      Pop_Size           : Pop_Size_T    := 20;
      Generations        : Natural       := 50;
      Mutation_Rate      : Unit_Interval := 0.05;
      Local_Search_Steps : Natural       := 10;
      Tournament_Size    : Tourney_K     := 3;
      Seed               : Natural       := 1;
      Use_Steepest       : Boolean       := True;
      Improve_All        : Boolean       := True;
   end record;

   type Result is record
      Best_Cost       : Real    := 0.0;
      Generations_Run : Natural := 0;
      Local_Improves  : Natural := 0;  -- improving LS moves across run
      Evaluations     : Natural := 0;
   end record;

   type Cost_Array is array (Positive range <>) of Real;

   ---------------------------------------------------------------------------
   -- Exceptions / numeric helpers
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;

   Epsilon_Tol : constant Real := 1.0E-10;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Default_Config
     (Pop_Size           : Pop_Size_T    := 20;
      Generations        : Natural       := 50;
      Mutation_Rate      : Unit_Interval := 0.05;
      Local_Search_Steps : Natural       := 10;
      Tournament_Size    : Tourney_K     := 3;
      Seed               : Natural       := 1;
      Use_Steepest       : Boolean       := True;
      Improve_All        : Boolean       := True) return Config
     with Global => null;

   function Config_Is_Valid (Cfg : Config) return Boolean
     with Global => null;
   --  True iff Tournament_Size ≤ Pop_Size (fields already in subtypes).

   ---------------------------------------------------------------------------
   -- Seeded RNG (32-bit LCG) for reproducible MA
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
   -- Bit-string state: OneMax (minimize zeros) / Hamming to target
   ---------------------------------------------------------------------------

   type Bit_String is array (Positive range <>) of Boolean;

   type Bit_Result is record
      Best_Bits       : Bit_String (1 .. Max_Bits) := [others => False];
      N               : Bit_Count := 1;
      Best_Cost       : Real    := 0.0;
      Generations_Run : Natural := 0;
      Local_Improves  : Natural := 0;
      Evaluations     : Natural := 0;
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

   function All_Ones (N : Bit_Count) return Bit_String
     with Global => null;

   function All_Zeros (N : Bit_Count) return Bit_String
     with Global => null;

   ---------------------------------------------------------------------------
   -- EA operators (bits): selection, crossover, mutation, local improve
   ---------------------------------------------------------------------------

   function Tournament_Pick
     (State : in out RNG_State;
      Costs : Cost_Array;
      K     : Tourney_K) return Positive
     with Pre => Costs'Length >= 2
            and then Natural (K) <= Costs'Length,
          Global => null;
   --  k-tournament (with replacement): return index of lowest Cost.

   function One_Point_Crossover
     (Parent_A, Parent_B : Bit_String;
      State              : in out RNG_State) return Bit_String
     with Pre => Parent_A'Length = Parent_B'Length
            and then Parent_A'Length >= 1
            and then Parent_A'Length <= Max_Bits,
          Global => null;
   --  Cut after a random locus in 0 .. N (0/N = copy of A or of B).

   function Mutate_Bits
     (Bits  : Bit_String;
      Rate  : Unit_Interval;
      State : in out RNG_State) return Bit_String
     with Pre => Bits'Length >= 1 and then Bits'Length <= Max_Bits,
          Global => null;
   --  Independent Bernoulli(Rate) flip per bit.

   function Local_Improve_Bits
     (Start     : Bit_String;
      Target    : Bit_String;
      Max_Steps : Natural;
      Steepest  : Boolean;
      Improves  : out Natural) return Bit_String
     with Pre => Start'Length = Target'Length
            and then Start'Length >= 1
            and then Start'Length <= Max_Bits,
          Global => null;
   --  Lamarckian bit-flip HC (steepest or first-improvement).

   function Local_Improve
     (Start     : Bit_String;
      Max_Steps : Natural;
      Steepest  : Boolean;
      Improves  : out Natural) return Bit_String
     with Pre => Start'Length >= 1 and then Start'Length <= Max_Bits,
          Global => null;
   --  OneMax specialization (target = all ones).

   ---------------------------------------------------------------------------
   -- Tiny TSP (n ≤ 10): order crossover + swap mutation + 2-opt LS
   ---------------------------------------------------------------------------

   type City_Index is range 1 .. Max_Cities;
   type Tour is array (City_Index range <>) of City_Index;
   type Dist_Matrix is
     array (City_Index range <>, City_Index range <>) of Non_Negative;

   type TSP_Result is record
      Best_Tour       : Tour (1 .. Max_Cities) := [others => 1];
      N               : City_Count := 2;
      Best_Length     : Non_Negative := 0.0;
      Generations_Run : Natural := 0;
      Local_Improves  : Natural := 0;
      Evaluations     : Natural := 0;
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

   function Is_Valid_Tour (T : Tour) return Boolean
     with Global => null;
   --  True iff T is a permutation of 1 .. T'Length.

   function Order_Crossover
     (Parent_A, Parent_B : Tour;
      State              : in out RNG_State) return Tour
     with Pre => Parent_A'Length = Parent_B'Length
            and then Parent_A'Length >= 2
            and then Parent_A'Length <= Max_Cities
            and then Parent_A'First = 1
            and then Parent_B'First = 1,
          Global => null;
   --  Classic OX: copy a random contiguous segment from A; fill rest
   --  from B in order, skipping cities already present.

   function Mutate_Tour
     (T     : Tour;
      Rate  : Unit_Interval;
      State : in out RNG_State) return Tour
     with Pre => T'Length >= 2 and then T'Length <= Max_Cities,
          Global => null;
   --  With Prob Rate, swap two random distinct positions.

   function Local_Improve_TSP
     (Start     : Tour;
      D         : Dist_Matrix;
      Max_Steps : Natural;
      Steepest  : Boolean;
      Improves  : out Natural) return Tour
     with Pre => Start'First = D'First (1)
            and then Start'Last = D'Last (1)
            and then D'First (1) = D'First (2)
            and then D'Last (1) = D'Last (2)
            and then Start'Length >= 2
            and then Start'Length <= Max_Cities,
          Global => null;
   --  2-opt hill climb (steepest or first-improvement), Lamarckian.

   ---------------------------------------------------------------------------
   -- Drivers
   ---------------------------------------------------------------------------

   function Minimize_OneMax
     (N : Bit_Count; Cfg : Config) return Bit_Result
     with Pre => Config_Is_Valid (Cfg), Global => null;
   --  Memetic EA maximizing ones ≡ minimizing Zero_Count.

   function Minimize_Hamming
     (Target : Bit_String; Cfg : Config) return Bit_Result
     with Pre => Target'Length >= 1
            and then Target'Length <= Max_Bits
            and then Config_Is_Valid (Cfg),
          Global => null;
   --  Same MA with cost = Hamming distance to Target.

   function Minimize_TSP
     (D : Dist_Matrix; Cfg : Config) return TSP_Result
     with Pre => D'First (1) = D'First (2)
            and then D'Last (1) = D'Last (2)
            and then D'Length (1) >= 2
            and then D'Length (1) <= Max_Cities
            and then Config_Is_Valid (Cfg),
          Global => null;
   --  Memetic EA on tiny TSP with OX + swap + 2-opt LS.

   ---------------------------------------------------------------------------
   -- Convenience packing
   ---------------------------------------------------------------------------

   function To_Result (R : Bit_Result) return Result
     with Global => null;

   function To_Result (R : TSP_Result) return Result
     with Global => null;

end Memetic_Algorithm;
