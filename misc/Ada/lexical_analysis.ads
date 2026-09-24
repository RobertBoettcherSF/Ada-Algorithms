pragma Ada_2022;

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package Lexical_Analysis is

   type Token_Kind is
     (Tk_Identifier,
      Tk_Keyword,
      Tk_Integer_Literal,
      Tk_Operator,
      Tk_Punctuation,
      Tk_End_Of_Input,
      Tk_Error);

   type Token is record
      Kind   : Token_Kind := Tk_End_Of_Input;
      Text   : Unbounded_String;
      Line   : Positive := 1;
      Column : Positive := 1;
   end record;

   type Token_Array is array (Positive range <>) of Token;

   -- Variant 1: Eager Tokenization (evaluates entire string at once into an array)
   function Tokenize_Eager (Input : String) return Token_Array
     with Global => null,
          Post   => Tokenize_Eager'Result'Length > 0;

   -- Variant 2: Two-Phase Analysis (Explicit Scanner and Evaluator)
   
   -- Phase A: Scanner (Identifies boundaries of the next lexeme)
   -- Incorporates Maximal Munch strategy for multi-character operators.
   procedure Extract_Lexeme
     (Input     : String;
      Start_Pos : Positive;
      Lex_Start : out Positive;
      Lex_End   : out Natural)
     with Global => null,
          Pre    => Input'Length > 0 and then Start_Pos <= Input'Last;

   -- Phase B: Evaluator (Determines token category and builds the token object)
   function Evaluate_Lexeme
     (Input     : String;
      Lex_Start : Positive;
      Lex_End   : Natural;
      Line      : Positive;
      Column    : Positive) return Token
     with Global => null;

   -- Variant 3: Lazy state-machine Tokenizer (Iterator pattern)
   type Lexer is tagged private;

   function Initialize (Input : String) return Lexer
     with Global => null;

   procedure Next_Token (Self : in out Lexer; Tok : out Token)
     with Global => null;

   -- Helper: Identifies if a given lexeme is a reserved keyword
   function Is_Keyword (Text : String) return Boolean
     with Global => null;

   -- Helper: Format token for readable output and debugging
   function To_String (Tok : Token) return String
     with Global => null;

   Lexical_Error : exception;

private
   type Lexer is tagged record
      Input_Text   : Unbounded_String;
      Current_Pos  : Positive := 1;
      Current_Line : Positive := 1;
      Current_Col  : Positive := 1;
   end record;

end Lexical_Analysis;
