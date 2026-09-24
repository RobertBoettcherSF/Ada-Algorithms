package LALR_Parser
  with Pure
is
   --  Basic type definitions to ensure strong typing throughout the algorithm.
   type Symbol_ID is new Integer range 0 .. 10_000;
   
   --  Terminal symbol 0 is reserved for EOF in typical LALR parsers.
   EOF_Symbol : constant Symbol_ID := 0;

   --  Subtypes to distinguish terminals (tokens) from non-terminals (grammar concepts).
   subtype Terminal_ID is Symbol_ID range 0 .. 5_000;
   subtype Non_Terminal_ID is Symbol_ID range 5_001 .. 10_000;

   type State_ID is new Integer range 0 .. 10_000;
   type Rule_ID is new Integer range 1 .. 10_000;

   --  Parsing actions for the LALR state machine.
   type Action_Kind is (Action_Error, Action_Shift, Action_Reduce, Action_Accept);

   type Action_Record (Kind : Action_Kind := Action_Error) is record
      case Kind is
         when Action_Shift =>
            Next_State : State_ID;
         when Action_Reduce =>
            Rule : Rule_ID;
         when Action_Accept | Action_Error =>
            null;
      end case;
   end record;

   --  Grammar production rule definition.
   type Rule_Def is record
      LHS        : Non_Terminal_ID;
      RHS_Length : Natural;
   end record;
   type Rule_Array is array (Rule_ID range <>) of Rule_Def;

   --  LALR Parse Tables. 
   type Action_Table is array (State_ID range <>, Terminal_ID range <>) of Action_Record;
   type Goto_Table is array (State_ID range <>, Non_Terminal_ID range <>) of State_ID;

   Invalid_State : constant State_ID := State_ID'Last;

   --  Input stream definition.
   type Token_Array is array (Positive range <>) of Terminal_ID;

   --  Exceptions for error handling and invariant violations.
   Parse_Error         : exception;
   Invalid_Table_Error : exception;

   --  =========================================================================
   --  Variant 1: Table-Driven LALR Parser Execution
   --  Executes a shift-reduce algorithm using provided LALR Action/Goto tables.
   --  =========================================================================
   function Parse (
      Actions     : Action_Table;
      Gotos       : Goto_Table;
      Rules       : Rule_Array;
      Input       : Token_Array;
      Start_State : State_ID
   ) return Boolean
     with Global => null,
          Pre    => Rules'Length > 0;

   --  =========================================================================
   --  Variant 2: LALR Table Generation Concept (State Merging)
   --  Demonstrates the core concept of LALR: merging LR(1) states that share 
   --  the same core item set (ignoring lookaheads).
   --  =========================================================================
   type Item_Core_ID is new Integer;
   
   type LR1_State_Def is record
      Core_ID : Item_Core_ID;
      --  In a full generator, this would contain transitions and lookaheads.
      --  For the state-merging algorithm, the Core_ID represents the LR(0) base.
   end record;
   
   type LR1_State_Array is array (State_ID range <>) of LR1_State_Def;
   type LALR_Map is array (State_ID range <>) of State_ID;

   function Generate_LALR_Mapping (LR1_States : LR1_State_Array) return LALR_Map
     with Global => null,
          Pre    => LR1_States'Length <= 10_000,
          Post   => Generate_LALR_Mapping'Result'Length = LR1_States'Length;

end LALR_Parser;
