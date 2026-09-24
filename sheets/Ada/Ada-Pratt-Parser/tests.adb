with Ada.Text_IO; use Ada.Text_IO;
with Ada.Characters.Latin_1;
with Pratt_Parser; use Pratt_Parser;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   --  Helper to track pass/fail state and print output
   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS — " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL — " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   --  Helper to parse, evaluate, verify a result, and safely free memory
   function Check_Eval (Expr : String; Expected : Integer) return Boolean is
      AST    : AST_Ptr := null;
      Result : Integer;
   begin
      AST    := Parse (Expr);
      Result := Evaluate (AST);
      Free_AST (AST);
      return Result = Expected;
   exception
      when others =>
         Free_AST (AST);
         return False;
   end Check_Eval;

   --  Helper to ensure Parse_Error is correctly raised
   function Check_Parse_Error (Expr : String) return Boolean is
      AST : AST_Ptr := null;
   begin
      AST := Parse (Expr);
      Free_AST (AST);
      return False; -- Should not reach here
   exception
      when Parse_Error =>
         return True;
      when others =>
         Free_AST (AST);
         return False;
   end Check_Parse_Error;

   --  Helper to ensure Evaluation_Error is correctly raised
   function Check_Eval_Error (Expr : String) return Boolean is
      AST : AST_Ptr := null;
   begin
      AST := Parse (Expr);
      
      --  Evaluate the AST to trigger the exception, consuming the 
      --  return value directly to avoid "assigned but never read" warnings.
      if Evaluate (AST) = 0 then
         null;
      end if;
      
      Free_AST (AST);
      return False; -- Should not reach here
   exception
      when Evaluation_Error =>
         Free_AST (AST);
         return True;
      when others =>
         Free_AST (AST);
         return False;
   end Check_Eval_Error;

begin
   -- TEST 1 — Numbers and Whitespaces
   Put_Line ("TEST 1 — Numbers and Whitespaces");
   Check ("1.1 Single digit", Check_Eval ("7", 7));
   Check ("1.2 Multiple digits", Check_Eval ("1234", 1234));
   Check ("1.3 Leading/trailing whitespaces", Check_Eval ("   42  ", 42));

   -- TEST 2 — Basic Arithmetic Operations
   Put_Line ("TEST 2 — Basic Arithmetic Operations");
   Check ("2.1 Addition", Check_Eval ("5 + 3", 8));
   Check ("2.2 Subtraction", Check_Eval ("10 - 4", 6));
   Check ("2.3 Negative result", Check_Eval ("2 - 10", -8));

   -- TEST 3 — Multiplication and Division
   Put_Line ("TEST 3 — Multiplication and Division");
   Check ("3.1 Multiplication", Check_Eval ("3 * 4", 12));
   Check ("3.2 Division", Check_Eval ("15 / 3", 5));
   Check ("3.3 Truncating division", Check_Eval ("10 / 3", 3));

   -- TEST 4 — Operator Precedence (+, -, *, /)
   Put_Line ("TEST 4 — Operator Precedence (+, -, *, /)");
   Check ("4.1 Mul over Add", Check_Eval ("1 + 2 * 3", 7));
   Check ("4.2 Add and Div", Check_Eval ("10 - 4 / 2", 8));
   Check ("4.3 Same precedence assoc", Check_Eval ("10 - 3 - 2", 5)); -- (10-3)-2

   -- TEST 5 — Exponentiation (Right-associative)
   Put_Line ("TEST 5 — Exponentiation (Right-associative)");
   Check ("5.1 Basic power", Check_Eval ("2 ^ 3", 8));
   Check ("5.2 Right associativity", Check_Eval ("2 ^ 3 ^ 2", 512));
   Check ("5.3 Precedence over Mul", Check_Eval ("2 * 3 ^ 2", 18));

   -- TEST 6 — Parentheses Grouping
   Put_Line ("TEST 6 — Parentheses Grouping");
   Check ("6.1 Override Add/Mul", Check_Eval ("(1 + 2) * 3", 9));
   Check ("6.2 Nested parens", Check_Eval ("((2 + 3) * (4 - 2))", 10));
   Check ("6.3 Parens with power", Check_Eval ("(2 ^ 3) ^ 2", 64));

   -- TEST 7 — Prefix Operators (+, -)
   Put_Line ("TEST 7 — Prefix Operators (+, -)");
   Check ("7.1 Negative number", Check_Eval ("-5", -5));
   Check ("7.2 Positive number", Check_Eval ("+5", 5));
   Check ("7.3 Double negative", Check_Eval ("--5", 5));

   -- TEST 8 — Prefix vs Exponent Precedence
   Put_Line ("TEST 8 — Prefix vs Exponent Precedence");
   Check ("8.1 Math convention -2^2", Check_Eval ("-2 ^ 2", -4));
   Check ("8.2 Parens (-2)^2", Check_Eval ("(-2) ^ 2", 4));
   Check ("8.3 Mixed prefix and add", Check_Eval ("-3 + 4", 1));

   -- TEST 9 — Complex Expressions
   Put_Line ("TEST 9 — Complex Expressions");
   Check ("9.1 Mixed all", Check_Eval ("-2 ^ 3 * (4 - 1)", -24));
   Check ("9.2 Spacing and tabs", Check_Eval ("10" & Ada.Characters.Latin_1.HT & "+" & Ada.Characters.Latin_1.LF & "2 * -3", 4));
   Check ("9.3 Long expression", Check_Eval ("1 + 2 - 3 * 4 / 2 ^ 2", 1 + 2 - 3 * 4 / 4)); -- 1+2-3 = 0

   -- TEST 10 — Syntax Errors (Empty and Invalid Characters)
   Put_Line ("TEST 10 — Syntax Errors (Empty and Invalid Characters)");
   Check ("10.1 Empty string", Check_Parse_Error (""));
   Check ("10.2 Only spaces", Check_Parse_Error ("   "));
   Check ("10.3 Invalid token", Check_Parse_Error ("1 + $ 2"));

   -- TEST 11 — Syntax Errors (Missing Operands)
   Put_Line ("TEST 11 — Syntax Errors (Missing Operands)");
   Check ("11.1 Missing right operand", Check_Parse_Error ("1 +"));
   Check ("11.2 Missing right operand (prefix)", Check_Parse_Error ("-"));
   Check ("11.3 Extraneous tokens", Check_Parse_Error ("1 + 2 3"));

   -- TEST 12 — Syntax Errors (Mismatched Parentheses)
   Put_Line ("TEST 12 — Syntax Errors (Mismatched Parentheses)");
   Check ("12.1 Unclosed paren", Check_Parse_Error ("(1 + 2"));
   Check ("12.2 Extra closing paren", Check_Parse_Error ("1 + 2)"));
   Check ("12.3 Empty parens", Check_Parse_Error ("()"));

   -- TEST 13 — Evaluation Errors
   Put_Line ("TEST 13 — Evaluation Errors");
   Check ("13.1 Division by zero", Check_Eval_Error ("10 / 0"));
   Check ("13.2 Negative exponent", Check_Eval_Error ("2 ^ -1"));
   Check ("13.3 Compound eval error", Check_Eval_Error ("(1 - 1) / (2 - 2)"));

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
