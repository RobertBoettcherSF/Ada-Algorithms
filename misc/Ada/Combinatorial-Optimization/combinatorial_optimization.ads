--  Combinatorial_Optimization — Ada 2023 educational SURVEY package for
--  Wikipedia "Combinatorial optimization": taxonomy of problems and methods,
--  with self-contained sketches for 0-1 knapsack (DP + greedy density +
--  exhaustive), MST (Kruskal), assignment cost / tiny brute-force, and
--  TSP (brute-force + 2-opt). Exact vs approx / metaheuristics noted via
--  Implemented vs Forthcoming tags; siblings are README links only.
--  Primary source:
--  https://en.wikipedia.org/wiki/Combinatorial_optimization
--  Siblings (README links only — no package deps):
--  Ada-Hungarian-Method, Ada-GRASP, Ada-Dynamic-Programming,
--  Ada-Integer-Linear-Programming, Ada-Exact-Cover, Ada-Genetic-Algorithms.

pragma Ada_2022;

package Combinatorial_Optimization
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity (educational caps)
   ---------------------------------------------------------------------------

   Max_Items      : constant := 20;   -- knapsack n
   Max_Capacity   : constant := 100;  -- knapsack DP table
   Max_Vertices   : constant := 12;   -- MST dense graphs
   Max_Cities     : constant := 8;    -- TSP brute / 2-opt
   Max_Assign     : constant := 8;    -- assignment brute-force n!

   subtype Item_Count    is Natural range 0 .. Max_Items;
   subtype Item_Index    is Positive range 1 .. Max_Items;
   subtype Capacity_Range is Natural range 0 .. Max_Capacity;
   subtype Vertex_Count  is Natural range 0 .. Max_Vertices;
   subtype Vertex_Index  is Positive range 1 .. Max_Vertices;
   subtype City_Count    is Natural range 0 .. Max_Cities;
   subtype City_Index    is Positive range 1 .. Max_Cities;
   subtype Assign_Count  is Natural range 0 .. Max_Assign;
   subtype Assign_Index  is Positive range 1 .. Max_Assign;

   type Weight_Array is array (Positive range <>) of Natural;
   type Value_Array  is array (Positive range <>) of Natural;
   type Selection    is array (Positive range <>) of Boolean;

   --  Dense undirected graph: Cost (I, J) for I < J used by Kruskal;
   --  Cost (I, I) ignored. Missing edges use No_Edge.
   type Cost is new Integer;
   No_Edge : constant Cost := Cost'Last;

   type Cost_Matrix is
     array (Positive range <>, Positive range <>) of Cost;

   type Edge_Record is record
      U, V : Positive := 1;
      W    : Cost     := 0;
   end record;

   type Edge_List is array (Positive range <>) of Edge_Record;

   type Tour is array (Positive range <>) of Positive;
   type Permutation is array (Positive range <>) of Positive;

   ---------------------------------------------------------------------------
   -- Result records
   ---------------------------------------------------------------------------

   type Knapsack_Result is record
      Best_Value  : Natural := 0;
      Best_Weight : Natural := 0;
      Selected    : Selection (1 .. Max_Items) := [others => False];
      N_Items     : Item_Count := 0;
      Exact       : Boolean := True;  -- False for greedy approx
   end record;

   type MST_Result is record
      Total_Weight : Cost := 0;
      Edges        : Edge_List (1 .. Max_Vertices) :=
        [others => (U => 1, V => 1, W => 0)];
      Edge_Count   : Natural := 0;
      Success      : Boolean := False;  -- False if graph disconnected
   end record;

   type Assignment_Result is record
      Total   : Cost := 0;
      Mapping : Permutation (1 .. Max_Assign) := [others => 1];
      N       : Assign_Count := 0;
      Exact   : Boolean := True;
   end record;

   type TSP_Result is record
      Best_Tour   : Tour (1 .. Max_Cities) := [others => 1];
      N           : City_Count := 0;
      Best_Length : Cost := 0;
      Exact       : Boolean := True;  -- False after 2-opt heuristic only
   end record;

   ---------------------------------------------------------------------------
   -- Taxonomy: problems and methods (Implemented vs Forthcoming)
   ---------------------------------------------------------------------------

   type Problem_Kind is
     (Knapsack,
      Assignment,
      TSP,
      MST,
      Set_Cover,
      ILP);

   type Method_Kind is
     (Exhaustive,
      Dynamic_Programming,
      Branch_and_Bound,
      Greedy,
      Local_Search,
      GRASP,
      Hungarian,
      Metaheuristic);

   type Problem_Info is record
      Kind        : Problem_Kind;
      Implemented : Boolean;
      Forthcoming : Boolean;
      --  Family padded to fixed width for simple embedding
      Family      : String (1 .. 16) := "                ";
   end record;

   type Method_Info is record
      Kind        : Method_Kind;
      Implemented : Boolean;
      Forthcoming : Boolean;
      Exactness   : String (1 .. 16) := "                ";
      --  "exact           ", "approx          ", "metaheuristic   "
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument  : exception;
   Capacity_Exceeded : exception;

   ---------------------------------------------------------------------------
   -- Taxonomy queries
   ---------------------------------------------------------------------------

   function Classify_Problem (Kind : Problem_Kind) return Problem_Info
     with Global => null;

   function Classify_Method (Kind : Method_Kind) return Method_Info
     with Global => null;

   function Problem_Name (Kind : Problem_Kind) return String
     with Global => null;

   function Method_Name (Kind : Method_Kind) return String
     with Global => null;

   function Implemented (Kind : Problem_Kind) return Boolean
     with Global => null;

   function Implemented (Kind : Method_Kind) return Boolean
     with Global => null;

   function Forthcoming (Kind : Problem_Kind) return Boolean
     with Global => null;

   function Forthcoming (Kind : Method_Kind) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- Knapsack utilities
   ---------------------------------------------------------------------------

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

   function Density (Value, Weight : Natural) return Long_Float
     with Global => null;
   --  Value/Weight; Weight = 0 treated as +inf-like large score via
   --  returning Long_Float (Value) * 1.0E9 when Weight = 0 and Value > 0.

   --  Exact 0-1 knapsack via classic DP table (n * Capacity).
   --  Requires Capacity <= Max_Capacity and n <= Max_Items.
   function Knapsack_DP
     (Weights  : Weight_Array;
      Values   : Value_Array;
      Capacity : Capacity_Range) return Knapsack_Result
     with Pre =>
       Weights'Length = Values'Length
       and then Weights'Length <= Max_Items
       and then Weights'Length >= 1
       and then Weights'First = Values'First,
          Global => null;

   --  Exhaustive 2^n subset search for tiny n (n <= 16 recommended).
   function Knapsack_Exhaustive
     (Weights  : Weight_Array;
      Values   : Value_Array;
      Capacity : Natural) return Knapsack_Result
     with Pre =>
       Weights'Length = Values'Length
       and then Weights'Length <= Max_Items
       and then Weights'Length >= 1
       and then Weights'First = Values'First,
          Global => null;

   --  Greedy-by-density approximation: sort items by Value/Weight desc,
   --  take while capacity allows (educational, not FPTAS).
   function Knapsack_Greedy_Density
     (Weights  : Weight_Array;
      Values   : Value_Array;
      Capacity : Natural) return Knapsack_Result
     with Pre =>
       Weights'Length = Values'Length
       and then Weights'Length <= Max_Items
       and then Weights'Length >= 1
       and then Weights'First = Values'First,
          Global => null;

   ---------------------------------------------------------------------------
   -- MST (Kruskal on dense Cost_Matrix)
   ---------------------------------------------------------------------------

   --  Undirected MST via Kruskal + Union-Find. Cost must be square,
   --  vertices 1 .. N; use No_Edge for absent edges. Success is False
   --  if the undirected graph is disconnected (forest returned).
   function MST_Kruskal
     (Costs : Cost_Matrix; N : Vertex_Count) return MST_Result
     with Pre =>
       N >= 1
       and then N <= Max_Vertices
       and then Costs'First (1) = 1
       and then Costs'First (2) = 1
       and then Costs'Last (1) >= N
       and then Costs'Last (2) >= N,
          Global => null;

   ---------------------------------------------------------------------------
   -- Assignment (cost of permutation + tiny brute-force)
   ---------------------------------------------------------------------------

   --  Sum_i Cost (i, Perm (i)). Perm must be a permutation of 1 .. N.
   function Assignment_Cost
     (Costs : Cost_Matrix;
      Perm : Permutation;
      N    : Assign_Count) return Cost
     with Pre =>
       N >= 1
       and then N <= Max_Assign
       and then Costs'First (1) = 1
       and then Costs'First (2) = 1
       and then Costs'Last (1) >= N
       and then Costs'Last (2) >= N
       and then Perm'First = 1
       and then Perm'Last >= N,
          Global => null;

   function Is_Permutation
     (Perm : Permutation; N : Assign_Count) return Boolean
     with Pre =>
       N >= 1
       and then N <= Max_Assign
       and then Perm'First = 1
       and then Perm'Last >= N,
          Global => null;

   --  Brute-force best assignment for n <= Max_Assign (n! enumerations).
   --  Minimises total cost. Hungarian algorithm is Forthcoming / sibling.
   function Assignment_Brute_Force
     (Costs : Cost_Matrix; N : Assign_Count) return Assignment_Result
     with Pre =>
       N >= 1
       and then N <= Max_Assign
       and then Costs'First (1) = 1
       and then Costs'First (2) = 1
       and then Costs'Last (1) >= N
       and then Costs'Last (2) >= N,
          Global => null;

   ---------------------------------------------------------------------------
   -- TSP (brute-force + 2-opt sketch)
   ---------------------------------------------------------------------------

   function Tour_Length
     (Dist : Cost_Matrix; T : Tour; N : City_Count) return Cost
     with Pre =>
       N >= 2
       and then N <= Max_Cities
       and then Dist'First (1) = 1
       and then Dist'First (2) = 1
       and then Dist'Last (1) >= N
       and then Dist'Last (2) >= N
       and then T'First = 1
       and then T'Last >= N,
          Global => null;

   --  Exact TSP: fix city 1 first, permute cities 2 .. N (n-1)!.
   function TSP_Brute_Force
     (Dist : Cost_Matrix; N : City_Count) return TSP_Result
     with Pre =>
       N >= 2
       and then N <= Max_Cities
       and then Dist'First (1) = 1
       and then Dist'First (2) = 1
       and then Dist'Last (1) >= N
       and then Dist'Last (2) >= N,
          Global => null;

   --  Apply one improving 2-opt move if any (steepest descent step).
   --  Returns True if an improving swap was applied.
   function Two_Opt_Improve
     (Dist : Cost_Matrix;
      T    : in out Tour;
      N    : City_Count) return Boolean
     with Pre =>
       N >= 4
       and then N <= Max_Cities
       and then Dist'First (1) = 1
       and then Dist'First (2) = 1
       and then Dist'Last (1) >= N
       and then Dist'Last (2) >= N
       and then T'First = 1
       and then T'Last >= N,
          Global => null;

   --  Repeated steepest 2-opt until local minimum. Exact = False.
   function TSP_Two_Opt
     (Dist  : Cost_Matrix;
      Start : Tour;
      N     : City_Count) return TSP_Result
     with Pre =>
       N >= 4
       and then N <= Max_Cities
       and then Dist'First (1) = 1
       and then Dist'First (2) = 1
       and then Dist'Last (1) >= N
       and then Dist'Last (2) >= N
       and then Start'First = 1
       and then Start'Last >= N,
          Global => null;

end Combinatorial_Optimization;
