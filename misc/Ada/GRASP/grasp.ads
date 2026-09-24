--  Grasp — Ada 2023 educational package for Wikipedia
--  "Greedy randomized adaptive search procedure" (Feo & Resende 1989):
--  multi-start metaheuristic. Each iteration (1) constructs a greedy
--  randomized solution via a Restricted Candidate List (RCL) controlled
--  by Alpha in [0,1], then (2) improves it to a local optimum. Keep the
--  best over Max_Iterations. Flagship demo: 0-1 knapsack (maximize
--  value under weight). Optional tiny TSP with nearest-neighbor RCL
--  construction + 2-opt local search.
--  Primary source:
--  https://en.wikipedia.org/wiki/Greedy_randomized_adaptive_search_procedure
--  Siblings (README links only — no package deps):
--  Ada-Local-Search, Ada-Min-Conflicts, Ada-Tabu-Search,
--  Ada-Combinatorial-Optimization (forthcoming).
--
--  Grasp_Generic (documented specialization): the shared RCL threshold
--  rule lives in Build_RCL (maximise) / Build_RCL_Min (minimise); knapsack
--  and TSP call those cores with problem-specific greedy scores.

pragma Ada_2022;

package Grasp
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain / capacity
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Unit_Interval is Real range 0.0 .. 1.0;

   Max_Items  : constant := 32;
   Max_Cities : constant := 10;
   --  Educational caps; knapsack tests focus on N <= 16, TSP on m <= 6.

   subtype Item_Count is Natural range 0 .. Max_Items;
   subtype Item_Index is Positive range 1 .. Max_Items;
   subtype City_Count is Positive range 2 .. Max_Cities;
   subtype City_Index is Positive range 1 .. Max_Cities;

   type Weight_Array is array (Positive range <>) of Natural;
   type Value_Array  is array (Positive range <>) of Natural;
   type Selection    is array (Positive range <>) of Boolean;
   type Score_Array  is array (Positive range <>) of Real;

   type Tour is array (City_Index range <>) of City_Index;
   type Dist_Matrix is
     array (City_Index range <>, City_Index range <>) of Non_Negative;

   ---------------------------------------------------------------------------
   -- Parameters / results
   ---------------------------------------------------------------------------

   --  Alpha           : RCL restrictiveness in [0,1]
   --                    0 = pure greedy (only best-scoring candidates)
   --                    1 = random among all feasible candidates
   --  Max_Iterations  : outer GRASP multi-start budget
   --  Seed            : LCG seed for reproducible RCL picks
   type Parameters is record
      Alpha          : Unit_Interval := 0.3;
      Max_Iterations : Positive      := 50;
      Seed           : Natural       := 1;
   end record;

   type Knapsack_Result is record
      Best_Value        : Natural := 0;
      Best_Weight       : Natural := 0;
      Selected          : Selection (1 .. Max_Items) := [others => False];
      N_Items           : Item_Count := 0;
      Iterations_Run    : Natural := 0;
      Best_Construction : Natural := 0;  -- best value seen after construct
      Local_Improves    : Natural := 0;  -- improving LS moves across run
   end record;

   type TSP_Result is record
      Best_Tour      : Tour (1 .. Max_Cities) := [others => 1];
      N              : City_Count := 2;
      Best_Length    : Non_Negative := 0.0;
      Iterations_Run : Natural := 0;
      Local_Improves : Natural := 0;
   end record;

   ---------------------------------------------------------------------------
   -- Restricted Candidate List (RCL)
   ---------------------------------------------------------------------------

   type RCL_Buffer is array (Positive range <>) of Natural;

   type RCL is record
      Items : RCL_Buffer (1 .. Max_Items) := [others => 0];
      Count : Natural := 0;
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions / helpers
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;

   Epsilon_Tol : constant Real := 1.0E-12;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Default_Parameters
     (Alpha          : Unit_Interval := 0.3;
      Max_Iterations : Positive      := 50;
      Seed           : Natural       := 1) return Parameters
     with Global => null;

   ---------------------------------------------------------------------------
   -- Seeded RNG (32-bit LCG) for reproducible RCL selection
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
   -- Knapsack utilities
   ---------------------------------------------------------------------------

   function Greedy_Score (Value, Weight : Natural) return Real
     with Global => null;
   --  Maximize score: Value/Weight when Weight > 0; else Real (Value)
   --  (zero-weight items are treated as free value).

   function Total_Weight
     (Weights : Weight_Array; Sel : Selection) return Natural
     with Pre =>
       Weights'Length = Sel'Length
       and then Weights'Length <= Max_Items
       and then Weights'First = Sel'First,
          Global => null;

   function Total_Value
     (Values : Value_Array; Sel : Selection) return Natural
     with Pre =>
       Values'Length = Sel'Length
       and then Values'Length <= Max_Items
       and then Values'First = Sel'First,
          Global => null;

   function Is_Feasible
     (Weights  : Weight_Array;
      Sel      : Selection;
      Capacity : Natural) return Boolean
     with Pre =>
       Weights'Length = Sel'Length
       and then Weights'Length <= Max_Items
       and then Weights'First = Sel'First,
          Global => null;

   ---------------------------------------------------------------------------
   -- Generic-style RCL cores (Grasp_Generic specialization point)
   ---------------------------------------------------------------------------

   --  Maximisation form (knapsack greedy scores):
   --    threshold = g_max - Alpha * (g_max - g_min)
   --    RCL = { e | g(e) >= threshold }
   --  Alpha = 0 → only best; Alpha = 1 → all candidates.
   --  Items/Scores are dense buffers indexed 1 .. Count.
   procedure Build_RCL
     (Items  : RCL_Buffer;
      Scores : Score_Array;
      Count  : Natural;
      Alpha  : Unit_Interval;
      List   : out RCL)
     with Pre =>
       Count <= Max_Items
       and then (Count = 0
                 or else (Count <= Items'Length
                          and then Count <= Scores'Length)),
          Global => null;

   --  Minimisation form (TSP distance-to-unused):
   --    threshold = d_min + Alpha * (d_max - d_min)
   --    RCL = { e | d(e) <= threshold }
   procedure Build_RCL_Min
     (Items  : RCL_Buffer;
      Scores : Score_Array;
      Count  : Natural;
      Alpha  : Unit_Interval;
      List   : out RCL)
     with Pre =>
       Count <= Max_Items
       and then (Count = 0
                 or else (Count <= Items'Length
                          and then Count <= Scores'Length)),
          Global => null;

   function Pick_From_RCL
     (List  : RCL;
      State : in out RNG_State) return Natural
     with Pre => List.Count >= 1, Global => null;
   --  Uniform random slot; returns the stored item id (caller domain).

   ---------------------------------------------------------------------------
   -- Knapsack RCL / construction / local search / GRASP driver
   ---------------------------------------------------------------------------

   --  Feasible candidates: unselected items that fit Remaining capacity.
   --  Scores = Greedy_Score (Value, Weight); uses Build_RCL (maximise).
   procedure Build_RCL_Knapsack
     (Weights   : Weight_Array;
      Values    : Value_Array;
      Sel       : Selection;
      Remaining : Natural;
      Alpha     : Unit_Interval;
      List      : out RCL)
     with Pre =>
       Weights'Length = Values'Length
       and then Weights'Length = Sel'Length
       and then Weights'Length <= Max_Items
       and then Weights'Length >= 1
       and then Weights'First = Values'First
       and then Weights'First = Sel'First,
          Global => null;

   procedure Construct_Solution_Knapsack
     (Weights  : Weight_Array;
      Values   : Value_Array;
      Capacity : Natural;
      Alpha    : Unit_Interval;
      State    : in out RNG_State;
      Sel      : out Selection)
     with Pre =>
       Weights'Length = Values'Length
       and then Weights'Length <= Max_Items
       and then Weights'Length >= 1
       and then Weights'First = Values'First,
          Global => null;
   --  Semi-greedy construction: repeatedly Build_RCL_Knapsack + Pick
   --  until no feasible candidate remains. Sel has bounds 1 .. N.

   procedure Local_Search_Knapsack
     (Weights  : Weight_Array;
      Values   : Value_Array;
      Capacity : Natural;
      Sel      : in out Selection;
      Improves : out Natural)
     with Pre =>
       Weights'Length = Values'Length
       and then Weights'Length = Sel'Length
       and then Weights'Length <= Max_Items
       and then Weights'Length >= 1
       and then Weights'First = Values'First
       and then Weights'First = Sel'First,
          Global => null;
   --  First-improvement local search: add moves (fit unused items) and
   --  1-1 swaps (drop one selected, add one unselected) until a local
   --  value maximum. Never decreases Total_Value. Improves counts moves.

   function Grasp_Knapsack
     (Weights  : Weight_Array;
      Values   : Value_Array;
      Capacity : Natural;
      Params   : Parameters) return Knapsack_Result
     with Pre =>
       Weights'Length = Values'Length
       and then Weights'Length <= Max_Items
       and then Weights'Length >= 1
       and then Weights'First = Values'First,
          Global => null;
   --  Classic GRASP: for I in 1 .. Max_Iterations do Construct then
   --  Local_Search; keep best (value, then lighter weight on ties).

   ---------------------------------------------------------------------------
   -- Optional TSP demo (nearest-neighbor RCL + 2-opt)
   ---------------------------------------------------------------------------

   function Tour_Length (T : Tour; D : Dist_Matrix) return Non_Negative
     with Pre =>
       T'First = D'First (1)
       and then T'Last = D'Last (1)
       and then D'First (1) = D'First (2)
       and then D'Last (1) = D'Last (2),
          Global => null;

   function Apply_2Opt (T : Tour; I, J : City_Index) return Tour
     with Pre =>
       I in T'Range and then J in T'Range and then I < J,
          Global => null;
   --  Reverse segment T (I+1 .. J).

   procedure Construct_Tour_NN_RCL
     (D     : Dist_Matrix;
      Alpha : Unit_Interval;
      State : in out RNG_State;
      T     : out Tour)
     with Pre =>
       D'First (1) = D'First (2)
       and then D'Last (1) = D'Last (2)
       and then D'Length (1) >= 2
       and then D'Length (1) <= Max_Cities,
          Global => null;
   --  Start at city 1; repeatedly pick unused city from distance RCL
   --  via Build_RCL_Min.

   procedure Local_Search_2Opt
     (D        : Dist_Matrix;
      T        : in out Tour;
      Improves : out Natural)
     with Pre =>
       T'First = D'First (1)
       and then T'Last = D'Last (1)
       and then D'First (1) = D'First (2)
       and then D'Last (1) = D'Last (2),
          Global => null;
   --  Steepest-descent 2-opt until local minimum tour length.

   function Grasp_TSP
     (D      : Dist_Matrix;
      Params : Parameters) return TSP_Result
     with Pre =>
       D'First (1) = D'First (2)
       and then D'Last (1) = D'Last (2)
       and then D'Length (1) >= 2
       and then D'Length (1) <= Max_Cities,
          Global => null;

   function Euclidean
     (X1, Y1, X2, Y2 : Real) return Non_Negative
     with Global => null;

end Grasp;
