package Packrat_Parser
  with SPARK_Mode => Off
is
   --  Strong domain types to avoid bare integers.
   type Rule_ID is new Positive;
   type Text_Index is new Positive;

   --  Types of matching rules available in this PEG parser
   type Rule_Kind is
     (Match_Char,
      Match_Any,
      Sequence,
      Choice,
      Zero_Or_More,
      Not_Predicate);

   --  A rule definition variant record representing an AST node of the grammar
   type Rule_Def (Kind : Rule_Kind := Match_Any) is record
      case Kind is
         when Match_Char =>
            Target_Char : Character;
         when Match_Any =>
            null;
         when Sequence | Choice =>
            Left_Rule  : Rule_ID;
            Right_Rule : Rule_ID;
         when Zero_Or_More | Not_Predicate =>
            Child_Rule : Rule_ID;
      end case;
   end record;

   --  The grammar is an array of rule definitions
   type Grammar_Array is array (Rule_ID range <>) of Rule_Def;

   --  Status of a parse attempt
   type Parse_Result_Status is (Success, Failure);

   --  The result of a parse operation containing the status and the next index on success
   type Parse_Result (Status : Parse_Result_Status := Failure) is record
      case Status is
         when Success =>
            Next_Index : Text_Index;
         when Failure =>
            null;
      end case;
   end record;

   --  Raised when an invalid grammar (e.g., out of bounds rule reference) is provided
   Invalid_Grammar : exception;

   --  Helper to validate that all rule references point to valid indices
   function Is_Valid_Grammar (Grammar : Grammar_Array) return Boolean;

   ----------------------------------------------------------------------------
   --  VARIANT 1: Naive Top-Down Recursive Descent
   --  Standard backtracking without memoization. Takes exponential time for
   --  certain ambiguous grammars. Safe from left-recursion crashes via cycle detection.
   ----------------------------------------------------------------------------
   function Parse_Naive
     (Grammar : Grammar_Array;
      Text    : String;
      Start   : Rule_ID) return Parse_Result
     with Pre => Grammar'Length > 0 and then Start in Grammar'Range;

   ----------------------------------------------------------------------------
   --  VARIANT 2: Standard Packrat Parser
   --  Uses memoization to guarantee linear parse time. Standard Packrat
   --  detects but does not resolve left-recursion.
   ----------------------------------------------------------------------------
   function Parse_Packrat
     (Grammar : Grammar_Array;
      Text    : String;
      Start   : Rule_ID) return Parse_Result
     with Pre => Grammar'Length > 0 and then Start in Grammar'Range;

   ----------------------------------------------------------------------------
   --  VARIANT 3: Packrat Parser with Left Recursion Support
   --  Implements the "longest match" seed growth technique (similar to Warth et al.)
   --  to natively handle direct left-recursion in linear time.
   ----------------------------------------------------------------------------
   function Parse_Packrat_Left_Rec
     (Grammar : Grammar_Array;
      Text    : String;
      Start   : Rule_ID) return Parse_Result
     with Pre => Grammar'Length > 0 and then Start in Grammar'Range;

end Packrat_Parser;
