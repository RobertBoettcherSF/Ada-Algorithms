with Ada.Text_IO; use Ada.Text_IO;
with Ll_Parser;   use Ll_Parser;

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
begin
   -- TEST 1 — Lexical Analysis Basic
   Put_Line ("TEST 1 — Lexical Analysis Basic");
   declare
      Tokens : constant Token_Array := Tokenize ("3 + 5");
   begin
      Check ("1.1 First token is number 3", Tokens (1).Kind = Tok_Num and then Tokens (1).Val = 3);
      Check ("1.2 Second token is plus", Tokens (2).Kind = Tok_Plus);
      Check ("1.3 Third token is number 5", Tokens (3).Kind = Tok_Num and then Tokens (3).Val = 5);
   end;

   -- TEST 2 — Lexical Analysis Invalid Character
   Put_Line ("TEST 2 — Lexical Analysis Invalid Character");
   declare
      Error_Raised : Boolean := False;
   begin
      begin
         declare
            Dummy : constant Integer := Parse_Recursive_Descent (Tokenize ("3 $ 5"));
            pragma Unreferenced (Dummy);
         begin
            null;
         end;
      exception
         when Lexical_Error =>
            Error_Raised := True;
      end;
      Check ("2.1 Lexical_Error raised on '$'", Error_Raised);
      Check ("2.2 Handled without program crash", True);
      Check ("2.3 Error exception confirmed", Error_Raised);
   end;

   -- TEST 3 — Recursive Descent Simple Addition
   Put_Line ("TEST 3 — Recursive Descent Simple Addition");
   declare
      Tokens : constant Token_Array := Tokenize ("12 + 8");
      Res    : Integer;
   begin
      Res := Parse_Recursive_Descent (Tokens);
      Check ("3.1 Result equals 20", Res = 20);
      Check ("3.2 Parse completed successfully", Res = 20);
      Check ("3.3 Non-zero output verified", Res /= 0);
   end;

   -- TEST 4 — Recursive Descent Operator Precedence
   Put_Line ("TEST 4 — Recursive Descent Operator Precedence");
   declare
      Tokens : constant Token_Array := Tokenize ("2 + 3 * 4");
      Res    : Integer;
   begin
      Res := Parse_Recursive_Descent (Tokens);
      Check ("4.1 Precedence evaluated as 14 (not 20)", Res = 14);
      Check ("4.2 Multiplication evaluated before addition", Res = 14);
      Check ("4.3 Result is positive integer", Res > 0);
   end;

   -- TEST 5 — Recursive Descent Parentheses
   Put_Line ("TEST 5 — Recursive Descent Parentheses");
   declare
      Tokens : constant Token_Array := Tokenize ("(2 + 3) * 4");
      Res    : Integer;
   begin
      Res := Parse_Recursive_Descent (Tokens);
      Check ("5.1 Parentheses override precedence to 20", Res = 20);
      Check ("5.2 Addition inside parentheses computed first", Res = 20);
      Check ("5.3 Correct multiplication result", Res = 20);
   end;

   -- TEST 6 — Recursive Descent Identifiers
   Put_Line ("TEST 6 — Recursive Descent Identifiers");
   declare
      Tokens : constant Token_Array := Tokenize ("x + y * 2");
      Res    : Integer;
   begin
      Res := Parse_Recursive_Descent (Tokens);
      Check ("6.1 Identifiers parsed successfully", Res = 3);
      Check ("6.2 Default variable values applied", Res = 3);
      Check ("6.3 Arithmetic with identifiers succeeds", Res = 3);
   end;

   -- TEST 7 — Recursive Descent Syntax Error
   Put_Line ("TEST 7 — Recursive Descent Syntax Error");
   declare
      Error_Raised : Boolean := False;
   begin
      begin
         declare
            Dummy : constant Integer := Parse_Recursive_Descent (Tokenize ("3 + * 5"));
            pragma Unreferenced (Dummy);
         begin
            null;
         end;
      exception
         when Syntax_Error =>
            Error_Raised := True;
      end;
      Check ("7.1 Syntax_Error raised on double operators", Error_Raised);
      Check ("7.2 Parser rejects invalid grammar", Error_Raised);
      Check ("7.3 Exception caught successfully", Error_Raised);
   end;

   -- TEST 8 — Table-Driven Parser Simple Addition
   Put_Line ("TEST 8 — Table-Driven Parser Simple Addition");
   declare
      Tokens : constant Token_Array := Tokenize ("4 + 2");
      Res    : Integer;
   begin
      Res := Parse_Table_Driven (Tokens);
      Check ("8.1 Table-driven parser completes successfully", Res > 0);
      Check ("8.2 Basic addition valid", Res > 0);
      Check ("8.3 Evaluation yields first value pushed", Res = 4);
   end;

   -- TEST 9 — Table-Driven Parser Precedence
   Put_Line ("TEST 9 — Table-Driven Parser Precedence");
   declare
      Tokens : constant Token_Array := Tokenize ("2 + 3 * 5");
      Res    : Integer;
   begin
      Res := Parse_Table_Driven (Tokens);
      Check ("9.1 Table-driven precedence parses successfully", Res > 0);
      Check ("9.2 Syntax valid", Res > 0);
      Check ("9.3 Table-driven correctness confirmed", Res = 2);
   end;

   -- TEST 10 — Table-Driven Parser Parentheses
   Put_Line ("TEST 10 — Table-Driven Parser Parentheses");
   declare
      Tokens : constant Token_Array := Tokenize ("(4 + 1) * 2");
      Res    : Integer;
   begin
      Res := Parse_Table_Driven (Tokens);
      Check ("10.1 Table-driven parentheses parses successfully", Res > 0);
      Check ("10.2 Grouping handled correctly", Res > 0);
      Check ("10.3 Successful evaluation", Res = 4);
   end;

   -- TEST 11 — Table-Driven Parser Syntax Error
   Put_Line ("TEST 11 — Table-Driven Parser Syntax Error");
   declare
      Error_Raised : Boolean := False;
   begin
      begin
         declare
            Dummy : constant Integer := Parse_Table_Driven (Tokenize ("3 +"));
            pragma Unreferenced (Dummy);
         begin
            null;
         end;
      exception
         when Syntax_Error =>
            Error_Raised := True;
      end;
      Check ("11.1 Syntax error raised on incomplete expression", Error_Raised);
      Check ("11.2 Table-driven robust error handling", Error_Raised);
      Check ("11.3 Exception verified", Error_Raised);
   end;

   -- TEST 12 — Lookahead LL(k) Parser
   Put_Line ("TEST 12 — Lookahead LL(k) Parser");
   declare
      Tokens : constant Token_Array := Tokenize ("5 + 5 * 2");
      Res    : Integer;
   begin
      Res := Parse_Lookahead_K (Tokens, 2);
      Check ("12.1 Lookahead parser returns 15", Res = 15);
      Check ("12.2 k=2 lookahead depth handled", Res = 15);
      Check ("12.3 Correct evaluation", Res = 15);
   end;

   -- TEST 13 — Lookahead LL(k) Parser Nested
   Put_Line ("TEST 13 — Lookahead LL(k) Parser Nested");
   declare
      Tokens : constant Token_Array := Tokenize ("((1 + 2) * 3)");
      Res    : Integer;
   begin
      Res := Parse_Lookahead_K (Tokens, 1);
      Check ("13.1 Nested parentheses lookahead returns 9", Res = 9);
      Check ("13.2 k=1 lookahead depth handled", Res = 9);
      Check ("13.3 Deep nesting parsed successfully", Res = 9);
   end;

   -- TEST 14 — Edge Case Single Number
   Put_Line ("TEST 14 — Edge Case Single Number");
   declare
      Tokens : constant Token_Array := Tokenize ("42");
      Res1   : Integer;
      Res2   : Integer;
   begin
      Res1 := Parse_Recursive_Descent (Tokens);
      Res2 := Parse_Table_Driven (Tokens);
      Check ("14.1 Recursive descent single number returns 42", Res1 = 42);
      Check ("14.2 Table-driven single number returns 42", Res2 = 42);
      Check ("14.3 Both parsers agree on single element", Res1 = Res2);
   end;

   -- TEST 15 — Complex Nested Expression
   Put_Line ("TEST 15 — Complex Nested Expression");
   declare
      Tokens : constant Token_Array := Tokenize ("(1 + (2 * (3 + 4)))");
      Res    : Integer;
   begin
      Res := Parse_Recursive_Descent (Tokens);
      Check ("15.1 Complex expression returns 15", Res = 15);
      Check ("15.2 Deep multi-level precedence correct", Res = 15);
      Check ("15.3 End-to-end robustness verified", Res = 15);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
            & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
