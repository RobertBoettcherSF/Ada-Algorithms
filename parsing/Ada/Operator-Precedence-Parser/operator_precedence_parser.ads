package Operator_Precedence_Parser
  with Preelaborate
is
   pragma Warnings (Off, "-gnatw.t");

   --  Custom types for strict typing
   type Token_Kind is
     (Tk_Number,
      Tk_Plus,
      Tk_Minus,
      Tk_Multiply,
      Tk_Divide,
      Tk_Power,
      Tk_Left_Paren,
      Tk_Right_Paren,
      Tk_End);

   type Value_Type is new Integer;
   type Precedence_Level is new Natural range 0 .. 10;
   type Associativity_Type is (Assoc_Left, Assoc_Right, Assoc_None);

   --  Token record with variant part for number values
   type Token_Type (Kind : Token_Kind := Tk_End) is record
      case Kind is
         when Tk_Number =>
            Value : Value_Type;
         when others =>
            null;
      end case;
   end record;

   type Token_Array is array (Positive range <>) of Token_Type;

   --  Exceptions specific to parsing and lexical analysis
   Parse_Error : exception;
   Lex_Error   : exception;

   --  Lexical analyzer: converts a string into an array of tokens
   function Lex (Input : String) return Token_Array
     with Global => null,
          Post   => Lex'Result'Length >= 1 and then
                    Lex'Result (Lex'Result'Last).Kind = Tk_End;

   --  Variant 1: Precedence Climbing algorithm
   --  Recursively builds the evaluated result based on minimum precedence thresholds.
   function Evaluate_Precedence_Climbing (Tokens : Token_Array) return Value_Type
     with Global => null,
          Pre    => Tokens'Length > 0 and then Tokens (Tokens'Last).Kind = Tk_End;

   --  Variant 2: Dijkstra's Shunting-yard algorithm
   --  Iteratively processes tokens using separate operator and operand stacks.
   function Evaluate_Shunting_Yard (Tokens : Token_Array) return Value_Type
     with Global => null,
          Pre    => Tokens'Length > 0 and then Tokens (Tokens'Last).Kind = Tk_End;

   --  Operator property helpers
   function Is_Operator (Kind : Token_Kind) return Boolean
     with Global => null;

   function Get_Precedence (Kind : Token_Kind) return Precedence_Level
     with Global => null,
          Pre    => Is_Operator (Kind);

   function Get_Associativity (Kind : Token_Kind) return Associativity_Type
     with Global => null,
          Pre    => Is_Operator (Kind);

   pragma Warnings (On, "-gnatw.t");
end Operator_Precedence_Parser;
