--  Branch_And_Bound — Ada 2023 educational package for Wikipedia
--  "Branch and bound": systematic tree search with optimistic bounds
--  and pruning. Primary concrete maximizer: 0-1 knapsack with the
--  Dantzig fractional-knapsack upper bound. Caps: items ≤ 32.
--  Primary source:
--  https://en.wikipedia.org/wiki/Branch_and_bound
--  Siblings (README links only — no package deps):
--  Ada-Combinatorial-Optimization, Ada-Dynamic-Programming,
--  Ada-Integer-Linear-Programming, Ada-Branch-and-Cut.

pragma Ada_2022;

package Branch_And_Bound
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Educational caps
   ---------------------------------------------------------------------------

   Max_Items    : constant := 32;
   Max_Capacity : constant := 10_000;

   subtype Item_Count     is Natural range 0 .. Max_Items;
   subtype Item_Index     is Positive range 1 .. Max_Items;
   subtype Capacity_Range is Natural range 0 .. Max_Capacity;

   --  Weight/Value/Selection accept any Positive First (parallel arrays
   --  share bounds via Same_Bounds). Density_Order stores absolute item
   --  indices in Weights'Range. Result.Selected packs logical 1 .. N_Items
   --  (slot K ↔ Weights'First + K - 1).

   type Weight_Array is array (Positive range <>) of Natural;
   type Value_Array  is array (Positive range <>) of Natural;
   type Selection    is array (Positive range <>) of Boolean;
   type Index_Array  is array (Positive range <>) of Positive;

   type Real is digits 15;

   ---------------------------------------------------------------------------
   -- Parameters / Result
   ---------------------------------------------------------------------------

   --  Sort_By_Density : branch in decreasing value/weight order (recommended).
   --  Verbose_Stats   : reserved; counters always filled in Result.
   type Parameters is record
      Sort_By_Density : Boolean := True;
      Verbose_Stats   : Boolean := False;
   end record;

   Default_Parameters : constant Parameters := (others => <>);

   type Result is record
      Best_Value  : Natural := 0;
      Best_Weight : Natural := 0;
      Selected    : Selection (1 .. Max_Items) := [others => False];
      N_Items     : Item_Count := 0;
      Nodes       : Natural := 0;   -- nodes visited (bound evaluated)
      Pruned      : Natural := 0;   -- nodes discarded by bound vs incumbent
      Exact       : Boolean := True;
      Success     : Boolean := False;
   end record;

   Invalid_Argument : exception;

   function Same_Bounds (W : Weight_Array; V : Value_Array) return Boolean
     with Global => null;
   function Same_Bounds (W : Weight_Array; S : Selection) return Boolean
     with Global => null;
   function Same_Bounds (V : Value_Array; S : Selection) return Boolean
     with Global => null;
   --  Body-defined ('First/'Last) so ads stays free of First pins.

   ---------------------------------------------------------------------------
   -- Utilities
   ---------------------------------------------------------------------------

   function Total_Weight
     (Weights : Weight_Array; Chosen : Selection) return Natural
     with Pre => Same_Bounds (Weights, Chosen)
                   and then Weights'Length <= Max_Items,
          Global => null;

   function Total_Value
     (Values : Value_Array; Chosen : Selection) return Natural
     with Pre => Same_Bounds (Values, Chosen)
                   and then Values'Length <= Max_Items,
          Global => null;

   function Is_Feasible
     (Weights  : Weight_Array;
      Chosen   : Selection;
      Capacity : Natural) return Boolean
     with Pre => Same_Bounds (Weights, Chosen)
                   and then Weights'Length <= Max_Items,
          Global => null;

   --  Density v/w; weight 0 yields a large sentinel when value > 0.
   function Density (Value, Weight : Natural) return Real
     with Global => null;

   --  Permutation of item indices 1 .. N sorted by decreasing density.
   function Density_Order
     (Weights : Weight_Array;
      Values  : Value_Array) return Index_Array
     with Pre => Same_Bounds (Weights, Values)
                   and then Weights'Length <= Max_Items,
          Post => Density_Order'Result'Length = Weights'Length,
          Global => null;
   --  Result is Index_Array (1 .. N) whose entries are absolute indices
   --  in Weights'Range (not always the integers 1 .. N; they are Weights indices).

   ---------------------------------------------------------------------------
   -- Dantzig fractional-knapsack upper bound
   ---------------------------------------------------------------------------

   --  Optimistic upper bound on *additional* value obtainable from the
   --  remaining items (listed in Order from First_Pos .. Order'Last) given
   --  Remaining capacity. Takes whole items by density, then a fractional
   --  piece of the next item (Dantzig bound for 0-1 knapsack relaxation).
   function Fractional_Bound
     (Weights   : Weight_Array;
      Values    : Value_Array;
      Order     : Index_Array;
      First_Pos : Positive;
      Remaining : Natural) return Real
     with Pre => Same_Bounds (Weights, Values)
                   and then Order'Length <= Weights'Length
                   and then Weights'Length <= Max_Items
                   and then First_Pos >= Order'First
                   and then First_Pos <= Order'Last + 1,
          Global => null;
   --  Order entries are absolute Weights indices; First_Pos indexes Order.

   --  Convenience: bound from scratch for the full instance (no decisions).
   function Fractional_Bound
     (Weights  : Weight_Array;
      Values   : Value_Array;
      Capacity : Natural) return Real
     with Pre => Same_Bounds (Weights, Values)
                   and then Weights'Length <= Max_Items,
          Global => null;

   ---------------------------------------------------------------------------
   -- Branch-and-bound 0-1 knapsack (maximize value)
   ---------------------------------------------------------------------------

   --  Depth-first BnB: at each position in Order, branch include / exclude.
   --  Prune when current_value + Fractional_Bound <= incumbent.
   function Solve_Knapsack_BnB
     (Weights  : Weight_Array;
      Values   : Value_Array;
      Capacity : Natural;
      Params   : Parameters := Default_Parameters) return Result
     with Pre => Same_Bounds (Weights, Values)
                   and then Weights'Length <= Max_Items
                   and then Capacity <= Max_Capacity;

   --  Alias used in some educational texts for the recursive search driver.
   function Branch_Knapsack
     (Weights  : Weight_Array;
      Values   : Value_Array;
      Capacity : Natural;
      Params   : Parameters := Default_Parameters) return Result
     with Pre => Same_Bounds (Weights, Values)
                   and then Weights'Length <= Max_Items
                   and then Capacity <= Max_Capacity;

   ---------------------------------------------------------------------------
   -- Exhaustive baseline (tiny n) for comparison
   ---------------------------------------------------------------------------

   function Knapsack_Exhaustive
     (Weights  : Weight_Array;
      Values   : Value_Array;
      Capacity : Natural) return Result
     with Pre => Same_Bounds (Weights, Values)
                   and then Weights'Length <= 20
                   and then Capacity <= Max_Capacity;

   function Same_Selection
     (A, B : Selection; N : Item_Count) return Boolean
     with Pre => N <= Max_Items
                   and then A'Length >= N and then B'Length >= N,
          Global => null;
   --  Compares the first N packed slots from each array's First.

end Branch_And_Bound;
