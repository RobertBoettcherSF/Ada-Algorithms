with Ada.Text_IO; use Ada.Text_IO;
with Operator_Precedence_Parser; use Operator_Precedence_Parser;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

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

   -- Helper to execute functional correctness tests via both algorithms
   procedure Check_Eval (Label : String; Expr : String; Expected : Value_Type) is
      Tokens : constant Token_Array := Lex (Expr);
      PC_Res : Value_Type;
      SY_Res : Value_Type;
   begin
      Check (Label & " Lexed", Tokens (Tokens'Last).Kind = Tk_End);
      PC_Res := Evaluate_Precedence_Climbing (Tokens);
      Check (Label & " Precedence Climbing", PC_Res = Expected);
      SY_Res := Evaluate_Shunting_Yard (Tokens);
      Check (Label & " Shunting Yard", SY_Res = Expected);
   exception
      when others =>
         Check (Label & " raised unexpected exception", False);
         Check (Label & " Dummy Assertion", False);
   end Check_Eval;

   -- Helper to execute error handling logic
   procedure Check_Parse_Error (Label : String; Expr : String) is
      Tokens : constant Token_Array := Lex (Expr);
      PC_Raised, SY_Raised : Boolean := False;
   begin
      Check (Label & " Lexed correctly", Tokens (Tokens'Last).Kind = Tk_End);

      begin
         declare
            Ignore1 : constant Value_Type := Evaluate_Precedence_Climbing (Tokens);
         begin
            null;
         end;
      exception
         when Parse_Error => PC_Raised := True;
      end;
      Check (Label & " Precedence Climbing raised Parse_Error", PC_Raised);

      begin
         declare
            Ignore2 : constant Value_Type := Evaluate_Shunting_Yard (Tokens);
         begin
            null;
         end;
      exception
         when Parse_Error => SY_Raised := True;
      end;
      Check (Label & " Shunting Yard raised Parse_Error", SY_Raised);
   end Check_Parse_Error;

begin
   Put_Line ("TEST 1 — Lexer Correctness & Edge Cases");
   declare
      Tks1 : constant Token_Array := Lex ("12 + 34");
   begin
      Check ("1.1 Proper token count", Tks1'Length = 4);
      Check ("1.2 First token is Number", Tks1 (Tks1'First).Kind = Tk_Number);
      Check ("1.3 Last token is End", Tks1 (Tks1'Last).Kind = Tk_End);
   end;

   Put_Line ("TEST 2 — Simple Addition");
   Check_Eval ("2.", "1 + 2", 3);

   Put_Line ("TEST 3 — Simple Subtraction");
   Check_Eval ("3.", "10 - 4", 6);

   Put_Line ("TEST 4 — Multiplication and Division");
   Check_Eval ("4.", "12 * 2 / 3", 8);

   Put_Line ("TEST 5 — Exponentiation");
   Check_Eval ("5.", "2 ^ 4", 16);

   Put_Line ("TEST 6 — Precedence Rules (+ and *)");
   Check_Eval ("6.", "2 + 3 * 4", 14);

   Put_Line ("TEST 7 — Precedence Rules (^ and *)");
   Check_Eval ("7.", "3 * 2 ^ 3", 24);

   Put_Line ("TEST 8 — Left Associativity (- and /)");
   Check_Eval ("8.", "10 - 4 - 2", 4);

   Put_Line ("TEST 9 — Right Associativity (^)");
   -- 2 ^ (3 ^ 2) = 2 ^ 9 = 512
   Check_Eval ("9.", "2 ^ 3 ^ 2", 512);

   Put_Line ("TEST 10 — Parentheses Handling");
   Check_Eval ("10.", "(2 + 3) * 4", 20);

   Put_Line ("TEST 11 — Complex Nested Expressions");
   Check_Eval ("11.", "2 ^ 3 * 2 + 10 / (5 - 3)", 21);

   Put_Line ("TEST 12 — Missing Parentheses Errors");
   Check_Parse_Error ("12.1", "(1 + 2");
   Check_Parse_Error ("12.2", "1 + 2)");

   Put_Line ("TEST 13 — Trailing Operators and Bad Syntax");
   Check_Parse_Error ("13.1", "1 + ");
   Check_Parse_Error ("13.2", "* 2");

   Put_Line ("TEST 14 — Arithmetic Errors");
   Check_Parse_Error ("14.1 Div-by-zero", "10 / (2 - 2)");
   Check_Parse_Error ("14.2 Neg Exponent", "2 ^ (0 - 1)");

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed during execution");
end Tests;
