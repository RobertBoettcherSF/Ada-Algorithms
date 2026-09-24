with Ada.Strings.Unbounded;
with Ada.Strings.Fixed;
with Ada.Strings;
with Ada.Characters.Handling;

package body Recursive_Descent_Parser is
   use Ada.Strings.Unbounded;

   -- Internal lexical tokens mapping the grammar's terminal symbols
   type Token_Kind is (Tok_None, Tok_Int, Tok_Plus, Tok_Minus,
                       Tok_Mul, Tok_Div, Tok_LParen, Tok_RParen,
                       Tok_End, Tok_Error);

   -- Lexical analyzer state representing the sliding window over the input
   type Parser_State (Len : Natural) is record
      Expr    : String (1 .. Len);
      Pos     : Positive := 1;
      Current : Token_Kind := Tok_None;
      Val     : Value_Type := 0;
   end record;

   -- Re-indexes any String to 1-based indexing for safe state mapping
   function Normalize (S : String) return String is
      Result : constant String (1 .. S'Length) := S;
   begin
      return Result;
   end Normalize;

   -- Formats a Value_Type safely without leading/trailing spaces
   function Image_Trimmed (Item : Value_Type) return String is
   begin
      return Ada.Strings.Fixed.Trim (Item'Image, Ada.Strings.Both);
   end Image_Trimmed;

   -- Advances the parser state to the next lexical token, skipping whitespace.
   procedure Next_Token (State : in out Parser_State) is
      use Ada.Characters.Handling;
   begin
      while State.Pos <= State.Expr'Last and then
            Is_Space (State.Expr (State.Pos))
      loop
         State.Pos := State.Pos + 1;
      end loop;

      if State.Pos > State.Expr'Last then
         State.Current := Tok_End;
         return;
      end if;

      declare
         Ch : constant Character := State.Expr (State.Pos);
      begin
         case Ch is
            when '+' =>
               State.Current := Tok_Plus;
               State.Pos := State.Pos + 1;
            when '-' =>
               State.Current := Tok_Minus;
               State.Pos := State.Pos + 1;
            when '*' =>
               State.Current := Tok_Mul;
               State.Pos := State.Pos + 1;
            when '/' =>
               State.Current := Tok_Div;
               State.Pos := State.Pos + 1;
            when '(' =>
               State.Current := Tok_LParen;
               State.Pos := State.Pos + 1;
            when ')' =>
               State.Current := Tok_RParen;
               State.Pos := State.Pos + 1;
            when '0' .. '9' =>
               State.Current := Tok_Int;
               State.Val := 0;
               -- Accumulate multidigit integer
               while State.Pos <= State.Expr'Last and then
                     Is_Digit (State.Expr (State.Pos))
               loop
                  State.Val := State.Val * 10 +
                               Value_Type (Character'Pos (State.Expr (State.Pos)) - Character'Pos ('0'));
                  State.Pos := State.Pos + 1;
               end loop;
            when others =>
               State.Current := Tok_Error;
               State.Pos := State.Pos + 1;
         end case;
      end;
   end Next_Token;


   -- ====================================================================
   -- VARIANT 1: Evaluator Implementation
   -- ====================================================================
   function Evaluate (Expression : String) return Value_Type is
      Norm_Expr : constant String := Normalize (Expression);
      State     : Parser_State := (Len     => Norm_Expr'Length,
                                   Expr    => Norm_Expr,
                                   Pos     => 1,
                                   Current => Tok_None,
                                   Val     => 0);
      Result    : Value_Type;

      function Parse_Expression (S : in out Parser_State) return Value_Type;
      function Parse_Term (S : in out Parser_State) return Value_Type;
      function Parse_Factor (S : in out Parser_State) return Value_Type;

      -- factor = "(" expression ")" | integer
      function Parse_Factor (S : in out Parser_State) return Value_Type is
         V : Value_Type;
      begin
         if S.Current = Tok_Int then
            V := S.Val;
            Next_Token (S);
            return V;
         elsif S.Current = Tok_LParen then
            Next_Token (S);
            V := Parse_Expression (S);
            if S.Current /= Tok_RParen then
               raise Syntax_Error with "Missing closing parenthesis";
            end if;
            Next_Token (S);
            return V;
         else
            raise Syntax_Error with "Unexpected token in factor";
         end if;
      end Parse_Factor;

      -- term = factor { ("*" | "/") factor }
      function Parse_Term (S : in out Parser_State) return Value_Type is
         V : Value_Type := Parse_Factor (S);
      begin
         while S.Current = Tok_Mul or else S.Current = Tok_Div loop
            if S.Current = Tok_Mul then
               Next_Token (S);
               V := V * Parse_Factor (S);
            else
               Next_Token (S);
               declare
                  Divisor : constant Value_Type := Parse_Factor (S);
               begin
                  if Divisor = 0 then
                     raise Evaluation_Error with "Division by zero";
                  end if;
                  V := V / Divisor;
               end;
            end if;
         end loop;
         return V;
      end Parse_Term;

      -- expression = term { ("+" | "-") term }
      function Parse_Expression (S : in out Parser_State) return Value_Type is
         V : Value_Type := Parse_Term (S);
      begin
         while S.Current = Tok_Plus or else S.Current = Tok_Minus loop
            if S.Current = Tok_Plus then
               Next_Token (S);
               V := V + Parse_Term (S);
            else
               Next_Token (S);
               V := V - Parse_Term (S);
            end if;
         end loop;
         return V;
      end Parse_Expression;

   begin
      Next_Token (State);

      if State.Current = Tok_End then
         raise Syntax_Error with "Empty expression";
      end if;

      Result := Parse_Expression (State);

      if State.Current /= Tok_End then
         raise Syntax_Error with "Unexpected trailing characters";
      end if;

      return Result;
   end Evaluate;


   -- ====================================================================
   -- VARIANT 2: Recognizer Implementation
   -- ====================================================================
   function Is_Valid (Expression : String) return Boolean is
      Norm_Expr : constant String := Normalize (Expression);
      State     : Parser_State := (Len     => Norm_Expr'Length,
                                   Expr    => Norm_Expr,
                                   Pos     => 1,
                                   Current => Tok_None,
                                   Val     => 0);

      procedure Check_Expression (S : in out Parser_State);
      procedure Check_Term (S : in out Parser_State);
      procedure Check_Factor (S : in out Parser_State);

      procedure Check_Factor (S : in out Parser_State) is
      begin
         if S.Current = Tok_Int then
            Next_Token (S);
         elsif S.Current = Tok_LParen then
            Next_Token (S);
            Check_Expression (S);
            if S.Current /= Tok_RParen then
               raise Syntax_Error;
            end if;
            Next_Token (S);
         else
            raise Syntax_Error;
         end if;
      end Check_Factor;

      procedure Check_Term (S : in out Parser_State) is
      begin
         Check_Factor (S);
         while S.Current = Tok_Mul or else S.Current = Tok_Div loop
            Next_Token (S);
            Check_Factor (S);
         end loop;
      end Check_Term;

      procedure Check_Expression (S : in out Parser_State) is
      begin
         Check_Term (S);
         while S.Current = Tok_Plus or else S.Current = Tok_Minus loop
            Next_Token (S);
            Check_Term (S);
         end loop;
      end Check_Expression;

   begin
      Next_Token (State);

      if State.Current = Tok_End then
         return False;
      end if;

      begin
         Check_Expression (State);
         return State.Current = Tok_End;
      exception
         when Syntax_Error =>
            return False;
      end;
   end Is_Valid;


   -- ====================================================================
   -- VARIANT 3: Translator Implementation
   -- ====================================================================
   function To_Postfix (Expression : String) return String is
      Norm_Expr : constant String := Normalize (Expression);
      State     : Parser_State := (Len     => Norm_Expr'Length,
                                   Expr    => Norm_Expr,
                                   Pos     => 1,
                                   Current => Tok_None,
                                   Val     => 0);
      Result    : Unbounded_String := Null_Unbounded_String;

      procedure Emit_Expression (S : in out Parser_State);
      procedure Emit_Term (S : in out Parser_State);
      procedure Emit_Factor (S : in out Parser_State);

      procedure Emit_Factor (S : in out Parser_State) is
      begin
         if S.Current = Tok_Int then
            Append (Result, Image_Trimmed (S.Val) & " ");
            Next_Token (S);
         elsif S.Current = Tok_LParen then
            Next_Token (S);
            Emit_Expression (S);
            if S.Current /= Tok_RParen then
               raise Syntax_Error with "Missing closing parenthesis";
            end if;
            Next_Token (S);
         else
            raise Syntax_Error with "Unexpected token in factor";
         end if;
      end Emit_Factor;

      procedure Emit_Term (S : in out Parser_State) is
      begin
         Emit_Factor (S);
         while S.Current = Tok_Mul or else S.Current = Tok_Div loop
            if S.Current = Tok_Mul then
               Next_Token (S);
               Emit_Factor (S);
               Append (Result, "* ");
            else
               Next_Token (S);
               Emit_Factor (S);
               Append (Result, "/ ");
            end if;
         end loop;
      end Emit_Term;

      procedure Emit_Expression (S : in out Parser_State) is
      begin
         Emit_Term (S);
         while S.Current = Tok_Plus or else S.Current = Tok_Minus loop
            if S.Current = Tok_Plus then
               Next_Token (S);
               Emit_Term (S);
               Append (Result, "+ ");
            else
               Next_Token (S);
               Emit_Term (S);
               Append (Result, "- ");
            end if;
         end loop;
      end Emit_Expression;

   begin
      Next_Token (State);

      if State.Current = Tok_End then
         raise Syntax_Error with "Empty expression";
      end if;

      Emit_Expression (State);

      if State.Current /= Tok_End then
         raise Syntax_Error with "Unexpected trailing characters";
      end if;

      -- Strip trailing space dynamically created by string construction
      declare
         Final_String : constant String := To_String (Result);
      begin
         if Final_String'Length > 0 and then
            Final_String (Final_String'Last) = ' '
         then
            return Final_String (Final_String'First .. Final_String'Last - 1);
         else
            return Final_String;
         end if;
      end;
   end To_Postfix;

end Recursive_Descent_Parser;
