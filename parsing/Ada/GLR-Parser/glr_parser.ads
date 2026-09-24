--  Generalized LR (GLR) Parser Framework (ISO/IEC 8652:2023)
--  Implements Tomita's algorithm variations for non-deterministic and ambiguous grammars.
package GLR_Parser is
   pragma Preelaborate;

   --  Strongly typed domains for parser entities
   type State_ID is new Natural;
   type Symbol_ID is new Natural;
   type Production_ID is new Positive;
   type Token_Index is new Positive;

   Max_RHS_Length : constant := 10;
   
   type Symbol_Category is (Terminal, Non_Terminal, Epsilon);

   type Symbol is record
      Category : Symbol_Category := Terminal;
      ID       : Symbol_ID := 0;
   end record;

   type Production is record
      LHS    : Symbol;
      Length : Natural range 0 .. Max_RHS_Length; -- 0 allows Right Nulled rules (RNGLR)
   end record;

   type Production_Array is array (Production_ID range <>) of Production;

   --  GLR Actions 
   type Action_Kind is (Action_Shift, Action_Reduce, Action_Accept, Action_Error);

   type Action_Record (Kind : Action_Kind := Action_Error) is record
      case Kind is
         when Action_Shift =>
            Next_State : State_ID;
         when Action_Reduce =>
            Prod_Ref : Production_ID;
         when Action_Accept | Action_Error =>
            null;
      end case;
   end record;

   --  A single state/symbol intersection can have multiple actions in GLR
   Max_Actions_Per_Cell : constant := 4;
   type Action_List is array (1 .. Max_Actions_Per_Cell) of Action_Record;
   
   type Action_Cell is record
      Count   : Natural range 0 .. Max_Actions_Per_Cell := 0;
      Actions : Action_List := [others => (Kind => Action_Error)];
   end record;

   type Parse_Table is array (State_ID range <>, Symbol_ID range <>) of Action_Cell;
   type Goto_Table is array (State_ID range <>, Symbol_ID range <>) of State_ID;

   type Token_Array is array (Token_Index range <>) of Symbol_ID;

   --  Results enum defining the outcomes of the GLR multi-path traversal
   type Parse_Result is (Parse_Success, Parse_Ambiguous, Parse_Syntax_Error, Parse_Lexical_Error);

   --  The Grammar definition containing all tables necessary for a GLR variant
   type Grammar (Max_State  : State_ID; 
                 Max_Symbol : Symbol_ID; 
                 Max_Prod   : Production_ID) is record
      Productions : Production_Array (1 .. Max_Prod);
      Actions     : Parse_Table (0 .. Max_State, 0 .. Max_Symbol);
      Gotos       : Goto_Table (0 .. Max_State, 0 .. Max_Symbol);
   end record;

   --  Exceptions for malformed grammars or API misuse
   Grammar_Error : exception;
   Invalid_State : exception;

   --  Standard Tomita GLR Parser
   --  Explores multiple parse paths using a branched stack approach.
   function Parse_GLR 
     (G : Grammar; Input : Token_Array) return Parse_Result
     with Pre => Input'Length > 0;

   --  Right Nulled GLR (RNGLR)
   --  Optimized for grammars with epsilon/nullable rules (Length = 0 reductions).
   function Parse_RNGLR 
     (G : Grammar; Input : Token_Array) return Parse_Result
     with Pre => Input'Length > 0;

   --  Binary Right Nulled GLR (BRNGLR)
   --  Enforces binarized structures (Max RHS length = 2).
   function Parse_BRNGLR 
     (G : Grammar; Input : Token_Array) return Parse_Result
     with Pre => Input'Length > 0;

   --  Scannerless GLR (SGLR)
   --  Operates directly on character streams rather than lexer tokens.
   function Parse_SGLR 
     (G : Grammar; Input : String) return Parse_Result
     with Pre => Input'Length > 0;

   --  Reduction Incorporated GLR (RIGLR)
   --  Simulates pre-computed reduction paths embedded in states.
   function Parse_RIGLR 
     (G : Grammar; Input : Token_Array) return Parse_Result
     with Pre => Input'Length > 0;

end GLR_Parser;
