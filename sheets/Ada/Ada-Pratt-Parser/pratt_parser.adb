with Ada.Unchecked_Deallocation;
with Ada.Characters.Latin_1;

package body Pratt_Parser is

   -----------------------------------------------------------------------------
   --  Helper Subprogram Declarations
   -----------------------------------------------------------------------------

   --  Advances the parser to the next token, skipping whitespace.
   procedure Advance (P : in out Parser);

   --  Returns the Left Binding Power (LBP) of a given token.
   function Get_Precedence (Tok : Token_Kind) return Precedence;

   --  Core Pratt Parsing function: parses an expression up to the given Right
   --  Binding Power (RBP).
   function Parse_Expression (P   : in out Parser;
                              RBP : Precedence) return AST_Ptr;

   --  Parselet for prefix (nud) tokens: numbers, unary operators, and parentheses.
   function Parse_Prefix (P   : in out Parser;
                          Tok : Token_Kind;
                          Val : Integer) return AST_Ptr;

   --  Parselet for infix (led) tokens: binary operators.
   function Parse_Infix (P    : in out Parser;
                         Left : AST_Ptr;
                         Tok  : Token_Kind) return AST_Ptr;

   -----------------------------------------------------------------------------
   --  Memory Management
   -----------------------------------------------------------------------------

   procedure Free is new Ada.Unchecked_Deallocation (AST_Node, AST_Ptr);

   procedure Free_AST (Node : in out AST_Ptr) is
   begin
      if Node /= null then
         case Node.Kind is
            when Expr_Number => null;
            when Expr_Prefix => Free_AST (Node.Prefix_Right);
            when Expr_Infix  =>
               Free_AST (Node.Left);
               Free_AST (Node.Infix_Right);
         end case;
         Free (Node);
      end if;
   end Free_AST;

   -----------------------------------------------------------------------------
   --  Lexical Analysis
   -----------------------------------------------------------------------------

   procedure Advance (P : in out Parser) is
      use Ada.Strings.Unbounded;
      C : Character;
   begin
      --  Skip over standard whitespace characters
      while P.Pos <= Length (P.Text) loop
         C := Element (P.Text, P.Pos);
         exit when C /= ' '
           and then C /= Ada.Characters.Latin_1.HT
           and then C /= Ada.Characters.Latin_1.CR
           and then C /= Ada.Characters.Latin_1.LF;
         P.Pos := P.Pos + 1;
      end loop;

      if P.Pos > Length (P.Text) then
         P.Current_Token := Tok_EOF;
         return;
      end if;

      C := Element (P.Text, P.Pos);

      case C is
         when '+' => P.Current_Token := Tok_Plus;     P.Pos := P.Pos + 1;
         when '-' => P.Current_Token := Tok_Minus;    P.Pos := P.Pos + 1;
         when '*' => P.Current_Token := Tok_Multiply; P.Pos := P.Pos + 1;
         when '/' => P.Current_Token := Tok_Divide;   P.Pos := P.Pos + 1;
         when '^' => P.Current_Token := Tok_Power;    P.Pos := P.Pos + 1;
         when '(' => P.Current_Token := Tok_LParen;   P.Pos := P.Pos + 1;
         when ')' => P.Current_Token := Tok_RParen;   P.Pos := P.Pos + 1;
         when '0' .. '9' =>
            declare
               Val : Integer := 0;
            begin
               while P.Pos <= Length (P.Text) and then Element (P.Text, P.Pos) in '0' .. '9' loop
                  Val := Val * 10 + Character'Pos (Element (P.Text, P.Pos)) - Character'Pos ('0');
                  P.Pos := P.Pos + 1;
               end loop;
               P.Current_Token := Tok_Number;
               P.Current_Value := Val;
            end;
         when others =>
            P.Current_Token := Tok_Invalid;
            P.Pos := P.Pos + 1;
      end case;
   end Advance;

   -----------------------------------------------------------------------------
   --  Pratt Parser Implementation
   -----------------------------------------------------------------------------

   function Get_Precedence (Tok : Token_Kind) return Precedence is
   begin
      case Tok is
         when Tok_Plus | Tok_Minus       => return Prec_Term;
         when Tok_Multiply | Tok_Divide  => return Prec_Factor;
         when Tok_Power                  => return Prec_Power;
         when others                     => return Prec_None;
      end case;
   end Get_Precedence;

   function Parse_Expression (P : in out Parser; RBP : Precedence) return AST_Ptr is
      Tok  : constant Token_Kind := P.Current_Token;
      Val  : constant Integer    := P.Current_Value;
      Left : AST_Ptr;
   begin
      if Tok = Tok_EOF then
         raise Parse_Error with "Unexpected end of input";
      end if;

      --  Consume the prefix token and parse it
      Advance (P);
      Left := Parse_Prefix (P, Tok, Val);

      --  Continue parsing infix expressions as long as the next token's Left
      --  Binding Power is strictly greater than our current Right Binding Power.
      while RBP < Get_Precedence (P.Current_Token) loop
         declare
            Infix_Tok : constant Token_Kind := P.Current_Token;
         begin
            Advance (P);
            Left := Parse_Infix (P, Left, Infix_Tok);
         end;
      end loop;

      return Left;
   end Parse_Expression;

   function Parse_Prefix (P : in out Parser; Tok : Token_Kind; Val : Integer) return AST_Ptr is
      Result : AST_Ptr;
   begin
      case Tok is
         when Tok_Number =>
            Result := new AST_Node'(Kind => Expr_Number, Value => Val);

         when Tok_Plus | Tok_Minus =>
            declare
               Right : AST_Ptr;
            begin
               --  Parse the right-hand side using the prefix binding power
               Right := Parse_Expression (P, Prec_Prefix);
               Result := new AST_Node'(Kind => Expr_Prefix, Prefix_Op => Tok, Prefix_Right => Right);
            end;

         when Tok_LParen =>
            --  Start a fresh expression ignoring previous precedence context
            Result := Parse_Expression (P, Prec_None);
            if P.Current_Token /= Tok_RParen then
               Free_AST (Result);
               raise Parse_Error with "Expected closing parenthesis";
            end if;
            Advance (P); --  Consume ')'

         when others =>
            raise Parse_Error with "Unexpected token for prefix expression";
      end case;
      return Result;
   end Parse_Prefix;

   function Parse_Infix (P : in out Parser; Left : AST_Ptr; Tok : Token_Kind) return AST_Ptr is
      Right     : AST_Ptr := null;
      RBP       : Precedence;
      Left_Copy : AST_Ptr := Left;
   begin
      case Tok is
         when Tok_Plus | Tok_Minus =>
            RBP := Prec_Term;
         when Tok_Multiply | Tok_Divide =>
            RBP := Prec_Factor;
         when Tok_Power =>
            --  Right associative: reduce binding power by 1 to let equal
            --  precedence operators bind to the right side.
            RBP := Prec_Power - 1;
         when others =>
            Free_AST (Left_Copy);
            raise Parse_Error with "Unexpected infix operator";
      end case;

      begin
         Right := Parse_Expression (P, RBP);
      exception
         when others =>
            --  Clean up previously parsed left side if parsing right side fails
            Free_AST (Left_Copy);
            raise;
      end;

      return new AST_Node'(Kind        => Expr_Infix,
                           Infix_Op    => Tok,
                           Left        => Left_Copy,
                           Infix_Right => Right);
   end Parse_Infix;

   -----------------------------------------------------------------------------
   --  Public API
   -----------------------------------------------------------------------------

   function Parse (Input : String) return AST_Ptr is
      use Ada.Strings.Unbounded;
      P : Parser;
   begin
      P.Text := To_Unbounded_String (Input);
      P.Pos := 1;
      Advance (P); --  Prime the first token

      if P.Current_Token = Tok_EOF then
         raise Parse_Error with "Empty input string";
      end if;

      declare
         Result : constant AST_Ptr := Parse_Expression (P, Prec_None);
      begin
         --  If we haven't consumed the entire string, it's a syntax error
         if P.Current_Token /= Tok_EOF then
            declare
               Temp : AST_Ptr := Result;
            begin
               Free_AST (Temp);
            end;
            raise Parse_Error with "Unexpected token at end of input";
         end if;
         return Result;
      end;
   end Parse;

   function Evaluate (Node : AST_Ptr) return Integer is
   begin
      if Node = null then
         raise Evaluation_Error with "Null AST node encountered";
      end if;

      case Node.Kind is
         when Expr_Number =>
            return Node.Value;

         when Expr_Prefix =>
            declare
               R_Val : constant Integer := Evaluate (Node.Prefix_Right);
            begin
               case Node.Prefix_Op is
                  when Tok_Plus  => return R_Val;
                  when Tok_Minus => return -R_Val;
                  when others    => raise Evaluation_Error with "Invalid prefix operator";
               end case;
            end;

         when Expr_Infix =>
            declare
               L_Val : constant Integer := Evaluate (Node.Left);
               R_Val : constant Integer := Evaluate (Node.Infix_Right);
            begin
               case Node.Infix_Op is
                  when Tok_Plus     => return L_Val + R_Val;
                  when Tok_Minus    => return L_Val - R_Val;
                  when Tok_Multiply => return L_Val * R_Val;
                  when Tok_Divide   =>
                     if R_Val = 0 then
                        raise Evaluation_Error with "Division by zero";
                     end if;
                     return L_Val / R_Val;
                  when Tok_Power    =>
                     if R_Val < 0 then
                        raise Evaluation_Error with "Negative exponent unsupported";
                     end if;
                     return L_Val ** R_Val;
                  when others       =>
                     raise Evaluation_Error with "Invalid infix operator";
               end case;
            end;
      end case;
   end Evaluate;

end Pratt_Parser;
