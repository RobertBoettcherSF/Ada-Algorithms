--  Hybrid_Algorithms — Ada 2023 educational SURVEY package for Wikipedia
--  "Hybrid algorithm": combine two or more algorithms that solve the
--  *same* problem, switching by data characteristics or over the run,
--  so the overall method inherits desirable traits of each component.
--  Taxonomy Hybrid_Kind tags Implemented vs Forthcoming sketches.
--  Primary source: https://en.wikipedia.org/wiki/Hybrid_algorithm
--  Siblings (README links only — no package deps):
--  Ada-Memetic-Algorithm, Ada-GRASP, Ada-Genetic-Algorithms,
--  Ada-Local-Search.

pragma Ada_2022;

package Hybrid_Algorithms
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain / capacity (educational caps)
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Unit_Interval is Real range 0.0 .. 1.0;

   Max_Sort_N   : constant := 256;
   Max_Items    : constant := 20;
   Max_Bits     : constant := 32;
   Max_Exact_N  : constant := 16;  -- exhaustive knapsack 2^n cap

   Default_Insertion_Threshold : constant Positive := 16;
   Default_Exact_Threshold     : constant Positive := 12;

   subtype Item_Count is Natural range 0 .. Max_Items;
   subtype Item_Index is Positive range 1 .. Max_Items;
   subtype Bit_Count  is Positive range 1 .. Max_Bits;

   type Int_Array is array (Positive range <>) of Integer;
   type Weight_Array is array (Positive range <>) of Natural;
   type Value_Array  is array (Positive range <>) of Natural;
   type Selection    is array (Positive range <>) of Boolean;
   type Bit_String   is array (Positive range <>) of Boolean;

   ---------------------------------------------------------------------------
   -- Config / results
   ---------------------------------------------------------------------------

   --  Insertion_Threshold : Switch_By_Size cutoff for Hybrid_Sort
   --  Exact_Threshold     : n <= Exact_Threshold → exhaustive else greedy
   --  Alpha               : RCL restrictiveness for construct+LS [0,1]
   --  Max_Iterations      : multi-start construct+LS budget
   --  Local_Search_Steps  : max improving hill-climb flips
   --  Seed                : LCG seed for stochastic sketches
   type Config is record
      Insertion_Threshold : Positive      := Default_Insertion_Threshold;
      Exact_Threshold     : Positive      := Default_Exact_Threshold;
      Alpha               : Unit_Interval := 0.3;
      Max_Iterations      : Positive      := 20;
      Local_Search_Steps  : Natural       := 50;
      Seed                : Natural       := 1;
   end record;

   type Sort_Stats is record
      Elements            : Natural := 0;
      Insertion_Segments  : Natural := 0;  -- times insertion ran on a slice
      Heap_Fallbacks      : Natural := 0;  -- introsort depth-limit heapsort
      Quick_Partitions    : Natural := 0;
      Max_Recursion_Depth : Natural := 0;
   end record;

   type Knapsack_Result is record
      Best_Value  : Natural := 0;
      Best_Weight : Natural := 0;
      Selected    : Selection (1 .. Max_Items) := [others => False];
      N_Items     : Item_Count := 0;
      Exact       : Boolean := False;  -- True when exhaustive path used
      Used_Greedy : Boolean := False;
      Local_Improves : Natural := 0;
   end record;

   type Bit_Result is record
      Best_Bits      : Bit_String (1 .. Max_Bits) := [others => False];
      N              : Bit_Count := 1;
      Best_Cost      : Real    := 0.0;  -- zeros remaining (OneMax min)
      Local_Improves : Natural := 0;
   end record;

   ---------------------------------------------------------------------------
   -- Taxonomy: Hybrid_Kind (Implemented vs Forthcoming)
   ---------------------------------------------------------------------------

   type Hybrid_Kind is
     (Switch_By_Size,        -- introsort-style / size cutoff
      Portfolio_Select,      -- run several solvers, keep best
      Memetic_GA_Local,      -- EA candidate + individual LS
      Grasp_Construct_LS,    -- greedy randomized construct + LS
      Exact_Then_Heuristic); -- exact for tiny n else heuristic

   type Hybrid_Info is record
      Kind        : Hybrid_Kind;
      Implemented : Boolean;
      Forthcoming : Boolean;
      Stochastic  : Boolean;
      --  Short fixed label for embedding / demos
      Label       : String (1 .. 24) := "                        ";
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions / helpers
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;

   Epsilon_Tol : constant Real := 1.0E-10;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Default_Config
     (Insertion_Threshold : Positive      := Default_Insertion_Threshold;
      Exact_Threshold     : Positive      := Default_Exact_Threshold;
      Alpha               : Unit_Interval := 0.3;
      Max_Iterations      : Positive      := 20;
      Local_Search_Steps  : Natural       := 50;
      Seed                : Natural       := 1) return Config
     with Global => null;

   ---------------------------------------------------------------------------
   -- Seeded RNG (32-bit LCG) for reproducible stochastic hybrids
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
   -- Taxonomy queries
   ---------------------------------------------------------------------------

   function Classify (Kind : Hybrid_Kind) return Hybrid_Info
     with Global => null;

   function Hybrid_Name (Kind : Hybrid_Kind) return String
     with Global => null;

   function Implemented (Kind : Hybrid_Kind) return Boolean
     with Global => null;

   function Forthcoming (Kind : Hybrid_Kind) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- Bit-string helpers (OneMax educational domain)
   ---------------------------------------------------------------------------

   function Zero_Count (Bits : Bit_String) return Natural
     with Global => null;

   function Ones_Count (Bits : Bit_String) return Natural
     with Global => null;

   function Flip_Bit (Bits : Bit_String; Index : Positive) return Bit_String
     with Pre => Index in Bits'Range, Global => null;

   function Random_Bit_String
     (State : in out RNG_State; N : Bit_Count) return Bit_String
     with Global => null;

   function All_Ones (N : Bit_Count) return Bit_String
     with Global => null;

   function All_Zeros (N : Bit_Count) return Bit_String
     with Global => null;

   function Copy_Bits (Src : Bit_String; N : Bit_Count) return Bit_String
     with Pre => Src'Length >= N, Global => null;

   ---------------------------------------------------------------------------
   -- Sorting building blocks + introsort-style hybrid
   ---------------------------------------------------------------------------

   function Is_Sorted (Data : Int_Array) return Boolean
     with Global => null;

   procedure Insertion_Sort_Range
     (Data : in out Int_Array; Lo, Hi : Positive)
     with Pre => Lo in Data'Range
            and then Hi in Data'Range
            and then Lo <= Hi,
          Global => null;

   procedure Heap_Sort_Range
     (Data : in out Int_Array; Lo, Hi : Positive)
     with Pre => Lo in Data'Range
            and then Hi in Data'Range
            and then Lo <= Hi,
          Global => null;

   --  Introsort-like: quicksort with median-of-three pivot; recurse with
   --  depth limit 2*floor(log2(n)); on depth limit use heapsort; when a
   --  slice length <= Insertion_Threshold use insertion sort.
   procedure Hybrid_Sort
     (Data                 : in out Int_Array;
      Stats                : out Sort_Stats;
      Insertion_Threshold  : Positive := Default_Insertion_Threshold)
     with Pre => Data'Length >= 0 and then Data'Length <= Max_Sort_N,
          Global => null;

   function Hybrid_Sort_Copy
     (Data                : Int_Array;
      Insertion_Threshold : Positive := Default_Insertion_Threshold)
      return Int_Array
     with Pre => Data'Length <= Max_Sort_N, Global => null;

   ---------------------------------------------------------------------------
   -- Knapsack utilities + size-switch / exact-then-heuristic
   ---------------------------------------------------------------------------

   function Total_Weight
     (Weights : Weight_Array; Sel : Selection) return Natural
     with Pre => Weights'Length = Sel'Length
            and then Weights'Length <= Max_Items
            and then Weights'First = Sel'First,
          Global => null;

   function Total_Value
     (Values : Value_Array; Sel : Selection) return Natural
     with Pre => Values'Length = Sel'Length
            and then Values'Length <= Max_Items
            and then Values'First = Sel'First,
          Global => null;

   function Is_Feasible
     (Weights  : Weight_Array;
      Sel      : Selection;
      Capacity : Natural) return Boolean
     with Pre => Weights'Length = Sel'Length
            and then Weights'Length <= Max_Items
            and then Weights'First = Sel'First,
          Global => null;

   function Density (Value, Weight : Natural) return Long_Float
     with Global => null;

   function Knapsack_Exhaustive
     (Weights  : Weight_Array;
      Values   : Value_Array;
      Capacity : Natural) return Knapsack_Result
     with Pre => Weights'Length = Values'Length
            and then Weights'Length >= 1
            and then Weights'Length <= Max_Exact_N
            and then Weights'First = Values'First,
          Global => null;

   function Knapsack_Greedy_Density
     (Weights  : Weight_Array;
      Values   : Value_Array;
      Capacity : Natural) return Knapsack_Result
     with Pre => Weights'Length = Values'Length
            and then Weights'Length >= 1
            and then Weights'Length <= Max_Items
            and then Weights'First = Values'First,
          Global => null;

   --  Exact_Then_Heuristic / Switch_By_Size on instance size:
   --  if n <= Exact_Threshold use exhaustive (Exact=True), else greedy
   --  density (Exact=False). Quality tradeoff: greedy may miss optimum.
   function Size_Switch_Knapsack
     (Weights         : Weight_Array;
      Values          : Value_Array;
      Capacity        : Natural;
      Exact_Threshold : Positive := Default_Exact_Threshold)
      return Knapsack_Result
     with Pre => Weights'Length = Values'Length
            and then Weights'Length >= 1
            and then Weights'Length <= Max_Items
            and then Weights'First = Values'First,
          Global => null;

   ---------------------------------------------------------------------------
   -- Memetic one-step: random/bit candidate + local hill-climb
   ---------------------------------------------------------------------------

   function Hill_Climb_OneMax
     (Start      : Bit_String;
      Max_Steps  : Natural := 50) return Bit_Result
     with Pre => Start'Length >= 1 and then Start'Length <= Max_Bits,
          Global => null;
   --  Steepest bit-flip ascent on ones (minimize Zero_Count).

   function Memetic_One_Step_OneMax
     (N   : Bit_Count;
      Cfg : Config := Default_Config) return Bit_Result
     with Global => null;
   --  Random bit-string + Hill_Climb_OneMax (Lamarckian one-step sketch).

   function Hill_Climb_Knapsack
     (Weights   : Weight_Array;
      Values    : Value_Array;
      Capacity  : Natural;
      Start     : Selection;
      Max_Steps : Natural := 50) return Knapsack_Result
     with Pre => Weights'Length = Values'Length
            and then Weights'Length = Start'Length
            and then Weights'Length >= 1
            and then Weights'Length <= Max_Items
            and then Weights'First = Values'First
            and then Weights'First = Start'First,
          Global => null;
   --  Flip neighborhood: add/remove one item if feasible; steepest value.

   function Memetic_One_Step_Knapsack
     (Weights  : Weight_Array;
      Values   : Value_Array;
      Capacity : Natural;
      Cfg      : Config := Default_Config) return Knapsack_Result
     with Pre => Weights'Length = Values'Length
            and then Weights'Length >= 1
            and then Weights'Length <= Max_Items
            and then Weights'First = Values'First,
          Global => null;

   ---------------------------------------------------------------------------
   -- Construct + local search (mini-GRASP style; no package deps)
   ---------------------------------------------------------------------------

   function Construct_Local_Search_Knapsack
     (Weights  : Weight_Array;
      Values   : Value_Array;
      Capacity : Natural;
      Cfg      : Config := Default_Config) return Knapsack_Result
     with Pre => Weights'Length = Values'Length
            and then Weights'Length >= 1
            and then Weights'Length <= Max_Items
            and then Weights'First = Values'First,
          Global => null;
   --  Multi-start: RCL density construction (Alpha) then hill-climb;
   --  keep best over Max_Iterations. Taxonomy: Grasp_Construct_LS.

   ---------------------------------------------------------------------------
   -- Portfolio: run two solvers, keep the better value
   ---------------------------------------------------------------------------

   function Portfolio_Knapsack
     (Weights  : Weight_Array;
      Values   : Value_Array;
      Capacity : Natural;
      Cfg      : Config := Default_Config) return Knapsack_Result
     with Pre => Weights'Length = Values'Length
            and then Weights'Length >= 1
            and then Weights'Length <= Max_Items
            and then Weights'First = Values'First,
          Global => null;
   --  Compare greedy density vs one construct+LS start; return better.
   --  Taxonomy: Portfolio_Select.

end Hybrid_Algorithms;
