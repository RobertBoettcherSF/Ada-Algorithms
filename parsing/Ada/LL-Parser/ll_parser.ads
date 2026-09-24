--  ========================================================================
--  Package: Ll_Parser
--  Description: Implementation of LL Parser algorithms (Table-Driven LL(1),
--               Recursive Descent LL(1), and Lookahead LL(k)) in Ada 2023.
--  ========================================================================

package Ll_Parser is

   -- Exceptions for error handling
   Lexical_Error : exception;
   Syntax_Error  : exception;

   -- Token types for the expression language
   type Token_Kind is
     (Tok_Id,
      Tok_Num,
      Tok_Plus,
      Tok_Star,
      Tok_Lparen,
      Tok_Rparen,
      Tok_Eof);

   type Token (Kind : Token_Kind := Tok_Eof) is record
      case Kind is
         when Tok_Id =>
            Name : Character;
         when Tok_Num =>
            Val  : Integer;
         when Tok_Plus | Tok_Star | Tok_Lparen | Tok_Rparen | Tok_Eof =>
            null;
      end case;
   end record;

   type Token_Array is array (Positive range <>) of Token;

   -- Variant 1: Table-Driven LL(1) Parser
   -- Uses an explicit parse stack and a predictive parsing table.
   function Parse_Table_Driven (Tokens : Token_Array) return Integer
     with Pre  => Tokens'Length > 0;

   -- Variant 2: Recursive Descent LL(1) Parser
   -- Uses mutually recursive functions corresponding to grammar non-terminals.
   function Parse_Recursive_Descent (Tokens : Token_Array) return Integer
     with Pre  => Tokens'Length > 0;

   -- Variant 3: Lookahead LL(k) Parser
   -- Uses up to k tokens of lookahead to resolve grammar paths.
   function Parse_Lookahead_K (Tokens : Token_Array; Lookahead_Depth : Positive := 2) return Integer
     with Pre  => Tokens'Length > 0 and then Lookahead_Depth in 1 .. 2;

   -- Lexical analyzer helper function
   function Tokenize (Input : String) return Token_Array;

end Ll_Parser;
