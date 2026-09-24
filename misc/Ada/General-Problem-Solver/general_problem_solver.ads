--  General_Problem_Solver — Ada 2023 educational package for Wikipedia
--  "General Problem Solver" (Newell, Shaw & Simon, 1957/1959): classic
--  means–ends analysis on a finite discrete domain with STRIPS-like
--  operators (preconditions, add-list, delete-list) and an ordered
--  difference table. Not a full historical GPS replica — a teaching
--  subset faithful to the means–ends idea.
--  Primary source: https://en.wikipedia.org/wiki/General_Problem_Solver
--  Siblings: Ada-Alpha-Beta-Pruning / Ada-Tabu-Search (README links).

pragma Ada_2022;

package General_Problem_Solver
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain: conditions as bits in a compact state word
   ---------------------------------------------------------------------------

   Max_Conditions : constant := 32;
   --  Conditions are numbered 1 .. Max_Conditions; bit (C - 1) of State.

   subtype Condition_Index is Positive range 1 .. Max_Conditions;

   type State is mod 2**Max_Conditions;
   --  Bitset of true conditions. Goal satisfaction is subset: every bit
   --  set in Goal must also be set in Current (extra true bits are fine).

   type Condition_Index_Array is array (Positive range <>) of Condition_Index;

   ---------------------------------------------------------------------------
   -- Operators (STRIPS-like) and plans
   ---------------------------------------------------------------------------

   Max_Operators     : constant := 64;
   Max_Plan_Length   : constant := 128;
   Default_Max_Depth : constant Natural := 32;

   subtype Operator_Index is Positive range 1 .. Max_Operators;

   --  Reduces = 0 means "no preferred difference"; otherwise the condition
   --  this operator is primarily intended to establish (means–ends hint).
   type Operator is record
      Preconditions : State   := 0;
      Add_List      : State   := 0;
      Delete_List   : State   := 0;
      Reduces       : Natural := 0;
   end record;

   type Operator_List is array (Positive range <>) of Operator;

   --  Plan entries are 1-based indices into the Operator_List passed to Solve.
   type Plan_Array is array (Positive range <>) of Natural;

   --  Difference table: most important condition first. Conditions absent
   --  from the table are considered least important (ascending index).
   type Difference_Order is array (Positive range <>) of Condition_Index;

   ---------------------------------------------------------------------------
   -- Exceptions / constants
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;

   Empty_Order : constant Difference_Order (1 .. 0) := [];

   ---------------------------------------------------------------------------
   -- Bit / state helpers
   ---------------------------------------------------------------------------

   function Bit (C : Condition_Index) return State
     with Inline, Global => null;
   --  Singleton mask with only condition C set.

   function Has (S : State; C : Condition_Index) return Boolean
     with Inline, Global => null;

   function Set_Bit (S : State; C : Condition_Index) return State
     with Inline, Global => null;

   function Clear_Bit (S : State; C : Condition_Index) return State
     with Inline, Global => null;

   function Make_State (Conditions : Condition_Index_Array) return State
     with Global => null;
   --  Union of Bit (C) for each listed condition.

   function Count_Bits (S : State) return Natural
     with Global => null;

   function Goal_Satisfied (Current, Goal : State) return Boolean
     with Inline, Global => null;
   --  True iff (Current and Goal) = Goal.

   function Difference_Mask (Current, Goal : State) return State
     with Inline, Global => null;
   --  Bits required by Goal that are missing from Current:
   --  Goal and (not Current).

   function Is_Subset (Sub, Super : State) return Boolean
     with Inline, Global => null;
   --  True iff every bit of Sub is set in Super.

   ---------------------------------------------------------------------------
   -- Operator application
   ---------------------------------------------------------------------------

   function Applicable (Current : State; Op : Operator) return Boolean
     with Inline, Global => null;
   --  True iff Is_Subset (Op.Preconditions, Current).

   function Apply (Current : State; Op : Operator) return State
     with Inline, Global => null;
   --  (Current and not Delete_List) or Add_List.

   function Reduces_Difference
     (Op   : Operator;
      Diff : Condition_Index) return Boolean
     with Global => null;
   --  True if Op prefers Diff (Reduces = Diff) or Diff is in Add_List.

   function Operator_Valid (Op : Operator) return Boolean
     with Global => null;
   --  Reduces in 0 .. Max_Conditions.

   ---------------------------------------------------------------------------
   -- Difference ordering (means–ends priority)
   ---------------------------------------------------------------------------

   function Ranked_Differences
     (Current, Goal : State;
      Order         : Difference_Order := Empty_Order)
      return Condition_Index_Array
     with Global => null;
   --  Missing goal conditions ordered by Order (most important first),
   --  then any remaining missing conditions by ascending index.

   ---------------------------------------------------------------------------
   -- Means–ends Solve
   ---------------------------------------------------------------------------

   function Solve
     (Start     : State;
      Goal      : State;
      Ops       : Operator_List;
      Plan      : out Plan_Array;
      Length    : out Natural;
      Max_Depth : Natural := Default_Max_Depth;
      Order     : Difference_Order := Empty_Order) return Boolean
     with Global => null;
   --  Classic recursive GPS: while differences remain, pick the most
   --  important difference, try operators that reduce it, recursively
   --  satisfy preconditions, then apply the operator. Depth-bounded;
   --  backtracks on failure. Returns True and fills Plan (1 .. Length)
   --  with operator indices into Ops when a plan is found.
   --  Raises Invalid_Argument if any Op.Reduces is out of range, or if
   --  Plan cannot hold a required step (Length would exceed Plan'Length).

   function Execute_Plan
     (Start  : State;
      Ops    : Operator_List;
      Plan   : Plan_Array;
      Length : Natural) return State
     with Global => null;
   --  Apply Plan (1 .. Length) in order; raises Invalid_Argument on bad
   --  index or Length > Plan'Length.

   function Plan_Reaches_Goal
     (Start  : State;
      Goal   : State;
      Ops    : Operator_List;
      Plan   : Plan_Array;
      Length : Natural) return Boolean
     with Global => null;
   --  True iff every step was Applicable when applied and the final
   --  state satisfies Goal.

   ---------------------------------------------------------------------------
   -- Toy domain: classic "drive son to school" (textbook GPS/STRIPS)
   ---------------------------------------------------------------------------

   Son_At_Home                : constant Condition_Index := 1;
   Son_At_School              : constant Condition_Index := 2;
   Car_Works                  : constant Condition_Index := 3;
   Car_Needs_Battery          : constant Condition_Index := 4;
   Have_Money                 : constant Condition_Index := 5;
   Have_Phone_Book            : constant Condition_Index := 6;
   Know_Phone_Number          : constant Condition_Index := 7;
   In_Communication_With_Shop : constant Condition_Index := 8;
   Shop_Knows_Problem         : constant Condition_Index := 9;
   Shop_Has_Money             : constant Condition_Index := 10;

   Drive_Son_To_School_Op   : constant Operator_Index := 1;
   Shop_Installs_Battery_Op : constant Operator_Index := 2;
   Tell_Shop_Problem_Op     : constant Operator_Index := 3;
   Telephone_Shop_Op        : constant Operator_Index := 4;
   Look_Up_Number_Op        : constant Operator_Index := 5;
   Give_Shop_Money_Op       : constant Operator_Index := 6;

   function School_Start return State
     with Global => null;
   --  son-at-home, car-needs-battery, have-money, have-phone-book

   function School_Goal return State
     with Global => null;
   --  son-at-school

   function School_Operators return Operator_List
     with Global => null;

   function School_Difference_Order return Difference_Order
     with Global => null;

   ---------------------------------------------------------------------------
   -- Toy domain: blocks-world lite
   ---------------------------------------------------------------------------

   Block_On_Table  : constant Condition_Index := 1;
   Block_Held      : constant Condition_Index := 2;
   Block_On_Target : constant Condition_Index := 3;

   Pickup_Op  : constant Operator_Index := 1;
   Putdown_Op : constant Operator_Index := 2;
   Stack_Op   : constant Operator_Index := 3;

   function Blocks_Start return State
     with Global => null;
   --  block-on-table

   function Blocks_Goal return State
     with Global => null;
   --  block-on-target

   function Blocks_Operators return Operator_List
     with Global => null;

end General_Problem_Solver;
