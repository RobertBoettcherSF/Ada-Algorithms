with Ada.Text_IO; use Ada.Text_IO;
with Recursive_Descent_Parser; use Recursive_Descent_Parser;

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

   -- Helper to detect specific exceptions
   function Evaluate_Fails_Syntax (Expr : String) return Boolean is
   begin
      if Evaluate (Expr) = 0 then
         return False;
      end if;
      return False;
   exception
      when Syntax_Error => return True;
      when others => return False;
   end Evaluate_Fails_Syntax;

   function Evaluate_Fails_Eval (Expr : String) return Boolean is
   begin
      if Evaluate (Expr) = 0 then
         return False;
      end if;
      return False;
   exception
      when Evaluation_Error => return True;
      when others => return False;
   end Evaluate_Fails_Eval;

   function Postfix_Fails_Syntax (Expr : String) return Boolean is
   begin
      if To_Postfix (Expr) = "" then
         return False;
      end if;
      return False;
   exception
      when Syntax_Error => return True;
      when others => return False;
   end Postfix_Fails_Syntax;

begin
   Put_Line ("TEST 1 — Evaluate Basic Addition and Subtraction");
   Check ("1.1 Single addition: 1 + 1", Evaluate ("1+1") = 2);
   Check ("1.2 Left associativity: 10 - 5 - 2", Evaluate ("10 - 5 - 2") = 3);
   Check ("1.3 Leading and trailing spaces: ' 0 + 42 '", Evaluate (" 0 + 42 ") = 42);

   Put_Line ("TEST 2 — Evaluate Multiplication and Division");
   Check ("2.1 Single multiplication: 2 * 3", Evaluate ("2*3") = 6);
   Check ("2.2 Left associativity mixed: 10 / 2 * 5", Evaluate ("10 / 2 * 5") = 25);
   Check ("2.3 Spaced division chaining: ' 100 / 10 / 2 '", Evaluate (" 100 / 10 / 2 ") = 5);

   Put_Line ("TEST 3 — Evaluate Correct Precedence Rules");
   Check ("3.1 Add vs Mult precedence: 2 + 3 * 4", Evaluate ("2 + 3 * 4") = 14);
   Check ("3.2 Sub vs Div precedence: 10 - 6 / 2", Evaluate ("10 - 6 / 2") = 7);
   Check ("3.3 Mixed complex precedence: 5 * 2 + 10 / 2", Evaluate ("5 * 2 + 10 / 2") = 15);

   Put_Line ("TEST 4 — Evaluate Parentheses Interactions");
   Check ("4.1 Overriding precedence: (2 + 3) * 4", Evaluate ("(2 + 3) * 4") = 20);
   Check ("4.2 Grouping right side: 10 / (5 - 3)", Evaluate ("10 / (5 - 3)") = 5);
   Check ("4.3 Deep nesting: (((10)))", Evaluate ("(((10)))") = 10);

   Put_Line ("TEST 5 — Evaluate Exception Handling (Invalid syntax)");
   Check ("5.1 Empty string", Evaluate_Fails_Syntax (""));
   Check ("5.2 Double operators", Evaluate_Fails_Syntax ("2 + * 3"));
   Check ("5.3 Invalid characters", Evaluate_Fails_Syntax ("2 + 3 x"));

   Put_Line ("TEST 6 — Evaluate Exception Handling (Runtime limits/bounds)");
   Check ("6.1 Missing closing parenthesis", Evaluate_Fails_Syntax ("(2 + 3"));
   Check ("6.2 Extraneous parenthesis", Evaluate_Fails_Syntax ("2 + 3)"));
   Check ("6.3 Division by zero", Evaluate_Fails_Eval ("10 / 0"));

   Put_Line ("TEST 7 — Recognizer (Is_Valid) Positive Structure");
   Check ("7.1 Single literal integer", Is_Valid ("1"));
   Check ("7.2 Binary expression", Is_Valid ("1 + 2"));
   Check ("7.3 Compound precedence structure", Is_Valid ("1 + 2 * 3"));

   Put_Line ("TEST 8 — Recognizer (Is_Valid) Nested Structures");
   Check ("8.1 Nested parenthesis", Is_Valid ("(((1)))"));
   Check ("8.2 Compound parenthesis pairs", Is_Valid ("(1+2)*(3-4)"));
   Check ("8.3 Spaced structures", Is_Valid (" ( 10 + 20 ) "));

   Put_Line ("TEST 9 — Recognizer (Is_Valid) Rejections");
   Check ("9.1 Empty strictly fails", not Is_Valid (""));
   Check ("9.2 Whitespace strictly fails", not Is_Valid ("   "));
   Check ("9.3 Truncated expression fails", not Is_Valid ("1 + "));

   Put_Line ("TEST 10 — Recognizer (Is_Valid) Malformed tokens");
   Check ("10.1 Stray left paren", not Is_Valid ("("));
   Check ("10.2 Invalid alphanumeric token", not Is_Valid ("1 + 2 a"));
   Check ("10.3 Reversed parenthesis", not Is_Valid (")("));

   Put_Line ("TEST 11 — Translation (To_Postfix) Base operations");
   Check ("11.1 Addition Translation", To_Postfix ("1 + 2") = "1 2 +");
   Check ("11.2 Subtraction Translation", To_Postfix ("10 - 2") = "10 2 -");
   Check ("11.3 Multiplication Translation", To_Postfix ("3 * 4") = "3 4 *");

   Put_Line ("TEST 12 — Translation (To_Postfix) Tree precedence mapping");
   Check ("12.1 Ascending precedence map", To_Postfix ("1 + 2 * 3") = "1 2 3 * +");
   Check ("12.2 Descending precedence map", To_Postfix ("2 * 3 + 4") = "2 3 * 4 +");
   Check ("12.3 Mixed precedence map", To_Postfix ("10 - 6 / 2") = "10 6 2 / -");

   Put_Line ("TEST 13 — Translation (To_Postfix) Precedence Overrides");
   Check ("13.1 Left parentheses override", To_Postfix ("(1 + 2) * 3") = "1 2 + 3 *");
   Check ("13.2 Right parentheses override", To_Postfix ("10 / (5 - 3)") = "10 5 3 - /");
   Check ("13.3 Strong left-associativity preservation", To_Postfix ("8 / 4 / 2") = "8 4 / 2 /");

   Put_Line ("TEST 14 — Translation (To_Postfix) Error Handling");
   Check ("14.1 Translation fails empty string", Postfix_Fails_Syntax (""));
   Check ("14.2 Translation fails incomplete string", Postfix_Fails_Syntax ("1 +"));
   Check ("14.3 Translation fails orphaned paren", Postfix_Fails_Syntax ("(1"));

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
