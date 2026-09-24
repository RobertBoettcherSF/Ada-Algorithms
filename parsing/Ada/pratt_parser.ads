with Ada.Strings.Unbounded;

package Pratt_Parser is

   --  Token definitions for our expression language
   type Token_Kind is (Tok_EOF, Tok_Number, Tok_Plus, Tok_Minus,
                       Tok_Multiply, Tok_Divide, Tok_Power,
                       Tok_LParen, Tok_RParen, Tok_Invalid);

   --  Precedence levels for the Pratt parser (Left Binding Power)
   --  Higher numbers mean higher precedence (tighter binding).
   type Precedence is new Natural range 0 .. 100;
   Prec_None   : constant Precedence := 0;
   Prec_Term   : constant Precedence := 20;  --  +, -
   Prec_Factor : constant Precedence := 30;  --  *, /
   Prec_Prefix : constant Precedence := 40;  --  Unary +, -
   Prec_Power  : constant Precedence := 50;  --  ^ (Right associative)

   --  AST Node definitions
   type Node_Kind is (Expr_Number, Expr_Prefix, Expr_Infix);

   type AST_Node;
   type AST_Ptr is access all AST_Node;

   type AST_Node (Kind : Node_Kind := Expr_Number) is record
      case Kind is
         when Expr_Number =>
            Value : Integer;
         when Expr_Prefix =>
            Prefix_Op    : Token_Kind;
            Prefix_Right : AST_Ptr;
         when Expr_Infix  =>
            Infix_Op    : Token_Kind;
            Left        : AST_Ptr;
            Infix_Right : AST_Ptr;
      end case;
   end record;

   --  Exceptions that can be raised during parsing or evaluation
   Parse_Error      : exception;
   Evaluation_Error : exception;

   --  Parses a mathematical expression and returns the root AST node.
   --  Raises Parse_Error on invalid syntax or mismatched parentheses.
   function Parse (Input : String) return AST_Ptr
     with Post => Parse'Result /= null;

   --  Evaluates an AST tree into an Integer.
   --  Raises Evaluation_Error on division by zero or negative exponents.
   function Evaluate (Node : AST_Ptr) return Integer
     with Pre => Node /= null;

   --  Recursively frees the memory allocated for the AST.
   procedure Free_AST (Node : in out AST_Ptr)
     with Post => Node = null;

private
   --  Parser state encapsulated to allow extensions and proper state tracking.
   type Parser is tagged limited record
      Text          : Ada.Strings.Unbounded.Unbounded_String;
      Pos           : Positive := 1;
      Current_Token : Token_Kind := Tok_EOF;
      Current_Value : Integer := 0;
   end record;

end Pratt_Parser;
