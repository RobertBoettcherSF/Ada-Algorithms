with Ada.Containers.Vectors;

--  LR_Parser
--  An Ada 2023 implementation of a table-driven LR parser engine.
--  Supports standard batch execution (non-preemptive) and token-by-token
--  stepwise execution (preemptive) for asynchronous parsing.
package LR_Parser is
   pragma Preelaborate;

   --  Strongly typed identifiers for grammar and state mechanics
   type State_Id is new Natural;
   type Symbol_Id is new Natural;
   type Rule_Id is new Positive;

   --  Convention: 0 represents the End-Of-File (EOF) terminal marker.
   End_Marker : constant Symbol_Id := 0;

   --  Actions achievable in a standard LR Shift-Reduce parser
   --  Note: Accept_Action is used instead of Accept because accept is a reserved keyword.
   type Action_Kind is (Error, Shift, Reduce, Accept_Action);
   
   --  Variant record carrying action-specific data
   type Action_Type (Kind : Action_Kind := Error) is record
      case Kind is
         when Error | Accept_Action => null;
         when Shift  => Next_State : State_Id;
         when Reduce => Rule       : Rule_Id;
      end case;
   end record;

   --  A designated invalid state for empty entries in the Goto table
   Invalid_State : constant State_Id := State_Id'Last;

   --  Defines a grammar production rule (A -> B C ...)
   --  Length is the number of symbols on the Right-Hand Side (RHS).
   type Production_Rule is record
      LHS    : Symbol_Id;
      Length : Natural;
   end record;

   --  Table Structures
   type Production_Array is array (Rule_Id range <>) of Production_Rule;
   type Action_Table is array (State_Id range <>, Symbol_Id range <>) of Action_Type;
   type Goto_Table is array (State_Id range <>, Symbol_Id range <>) of State_Id;

   --  The LR Parser Engine carrying static tables for a given grammar
   type LR_Parser_Engine (
      Max_State       : State_Id;
      Max_Terminal    : Symbol_Id;
      Max_Nonterminal : Symbol_Id;
      Max_Rule        : Rule_Id
   ) is tagged record
      Actions : Action_Table (0 .. Max_State, 0 .. Max_Terminal);
      Gotos   : Goto_Table (0 .. Max_State, 0 .. Max_Nonterminal);
      Rules   : Production_Array (1 .. Max_Rule);
   end record;

   --  Containers for parsed derivations and internal stack
   package Rule_Vectors is new Ada.Containers.Vectors (Index_Type   => Positive,
                                                       Element_Type => Rule_Id);
   subtype Derivation_Sequence is Rule_Vectors.Vector;

   package State_Vectors is new Ada.Containers.Vectors (Index_Type   => Positive,
                                                        Element_Type => State_Id);

   --  Parser internal state status
   type Parse_Status is (Running, Accepted, Syntax_Error);

   --  Holds the execution context for stepwise parsing
   type Parser_Execution_State is record
      Stack        : State_Vectors.Vector;
      Derivation   : Derivation_Sequence;
      Status       : Parse_Status := Running;
   end record;

   --  Unconstrained array of input tokens
   type Symbol_Array is array (Positive range <>) of Symbol_Id;

   Syntax_Error_Exception : exception;

   --  VARIANT 1: Static table validation
   --  Checks that the engine tables are well-formed (valid rule indices and reachable Accept).
   function Validate_Engine (Engine : LR_Parser_Engine) return Boolean;

   --  Initializes a fresh resumable parser context with State 0 on the stack.
   function Initialize_Parser return Parser_Execution_State
      with Post => Initialize_Parser'Result.Status = Running;

   --  VARIANT 2: Preemptive (stepwise) parse
   --  Feeds a single token, reducing until a Shift or Accept_Action is reached.
   procedure Feed_Token (
      Engine : LR_Parser_Engine;
      State  : in out Parser_Execution_State;
      Token  : Symbol_Id
   ) with Pre => State.Status = Running;

   --  VARIANT 3: Non-preemptive (batch) parse
   --  Consumes the full input array until Accept_Action, raising Syntax_Error_Exception on failure.
   function Parse (Engine : LR_Parser_Engine; Input : Symbol_Array) return Derivation_Sequence
      with Pre => Validate_Engine (Engine);

end LR_Parser;
