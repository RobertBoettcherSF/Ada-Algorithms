with Ada.Containers.Vectors;

package PDDL_Planner is

   --  Strongly typed custom aliases for domain-specific data
   Max_Propositions : constant := 128;
   type Proposition_ID is range 1 .. Max_Propositions;
   
   Max_Actions : constant := 1024;
   type Action_ID is range 1 .. Max_Actions;

   --  State is represented as a packed bit-vector for high performance
   --  Set/unset propositions translate to bitwise operations.
   type State is array (Proposition_ID) of Boolean;
   pragma Pack (State);

   Empty_State : constant State := [others => False];

   --  Type for convenient instantiation of states from lists of propositions
   type Proposition_Array is array (Positive range <>) of Proposition_ID;

   --  An action in the Planning Domain Definition Language (STRIPS-style)
   type Action is record
      ID       : Action_ID;
      Pre_Pos  : State := Empty_State;
      Pre_Neg  : State := Empty_State;
      Eff_Add  : State := Empty_State;
      Eff_Del  : State := Empty_State;
   end record;

   type Domain is array (Action_ID range <>) of Action;

   --  Plan sequence container
   package Plan_Vectors is new Ada.Containers.Vectors 
     (Index_Type => Positive, Element_Type => Action_ID);
   
   type Plan is record
      Steps : Plan_Vectors.Vector;
   end record;
   
   Empty_Plan : constant Plan := (Steps => Plan_Vectors.Empty_Vector);

   --  A specific planning problem definition
   type Problem is record
      Initial  : State;
      Goal_Pos : State;
      Goal_Neg : State;
   end record;

   --  Named exceptions for edge cases and errors
   No_Plan_Found  : exception;
   Invalid_Action : exception;

   --  Helper to easily construct a state from an array of Proposition_IDs
   function Make_State (Props : Proposition_Array) return State
     with Global => null;

   --  Checks if an action can be legally applied to the current state
   function Is_Applicable (Current : State; Act : Action) return Boolean
     with Global => null;

   --  Calculates the successor state after applying an action
   --  Raises Invalid_Action if the action is not applicable.
   function Apply_Action (Current : State; Act : Action) return State
     with Global => null;

   --  Verifies if the target goal conditions are met in the current state
   function Is_Goal_Met (Current : State; Goal_Pos, Goal_Neg : State) return Boolean
     with Global => null;

   --  Finds the optimal (shortest) plan using Breadth-First Search
   --  Raises No_Plan_Found if the goal is unreachable.
   function Solve_BFS (Dom : Domain; Prob : Problem) return Plan;

   --  Finds any valid plan using Depth-First Search up to Max_Depth
   --  Raises No_Plan_Found if no plan is found within the limit.
   function Solve_DFS (Dom : Domain; Prob : Problem; Max_Depth : Natural := 20) return Plan;

end PDDL_Planner;
