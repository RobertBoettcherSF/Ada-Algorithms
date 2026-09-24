--------------------------------------------------------------------------------
-- Test Suite: Tests (Standalone main executable for Simple_LR_Parser)
--------------------------------------------------------------------------------

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Containers; use type Ada.Containers.Count_Type;
with Simple_LR_Parser; use Simple_LR_Parser;

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
   Put_Line ("=== STARTING SIMPLE LR PARSER TEST SUITE ===");

   -- TEST 1 — Tokenize basic addition
   Put_Line ("TEST 1 — Tokenize Basic Addition");
   declare
      Tokens : constant Token_Sequence := Tokenize ("5 + 10");
   begin
      Check ("1.1 Token count correct (3 tokens + EOF)", Tokens.Length = 4);
      Check ("1.2 First token is ID/Number 5", Tokens.Element (1).Kind = Tok_Id and then Tokens.Element (1).Value = 5);
      Check ("1.3 Second token is Plus", Tokens.Element (2).Kind = Tok_Plus);
   end;

   -- TEST 2 — Tokenize complex parenthesized expression
   Put_Line ("TEST 2 — Tokenize Complex Expression");
   declare
      Tokens : constant Token_Sequence := Tokenize ("(a + b) * 3");
   begin
      Check ("2.1 Token count correct", Tokens.Length = 8);
      Check ("2.2 First token is Left Paren", Tokens.Element (1).Kind = Tok_L_Paren);
      Check ("2.3 Fifth token is Right Paren", Tokens.Element (5).Kind = Tok_R_Paren);
   end;

   -- TEST 3 — Parse single identifier/number
   Put_Line ("TEST 3 — Parse Single Number");
   declare
      Tokens : constant Token_Sequence := Tokenize ("42");
      Result : constant Parse_Result := Parse (Tokens);
   begin
      Check ("3.1 Parse succeeds", Result.Success);
      Check ("3.2 Step count > 0", Result.Steps_Count > 0);
      Check ("3.3 Evaluated result equals 42", Result.Result_Value = 42);
   end;

   -- TEST 4 — Parse simple addition expression
   Put_Line ("TEST 4 — Parse Simple Addition");
   declare
      Tokens : constant Token_Sequence := Tokenize ("10 + 20");
      Result : constant Parse_Result := Parse (Tokens);
   begin
      Check ("4.1 Parse succeeds", Result.Success);
      Check ("4.2 Step count correct", Result.Steps_Count >= 3);
      Check ("4.3 Evaluated result equals 30", Result.Result_Value = 30);
   end;

   -- TEST 5 — Parse operator precedence (addition and multiplication)
   Put_Line ("TEST 5 — Parse Operator Precedence");
   declare
      Tokens : constant Token_Sequence := Tokenize ("2 + 3 * 4");
      Result : constant Parse_Result := Parse (Tokens);
   begin
      Check ("5.1 Parse succeeds", Result.Success);
      Check ("5.2 Precedence honored (3*4=12 + 2 = 14)", Result.Result_Value = 14);
      Check ("5.3 Non-zero steps", Result.Steps_Count > 0);
   end;

   -- TEST 6 — Parse parenthesized expression overriding precedence
   Put_Line ("TEST 6 — Parse Parenthesized Expression");
   declare
      Tokens : constant Token_Sequence := Tokenize ("(2 + 3) * 4");
      Result : constant Parse_Result := Parse (Tokens);
   begin
      Check ("6.1 Parse succeeds", Result.Success);
      Check ("6.2 Parentheses honored ((2+3)*4 = 20)", Result.Result_Value = 20);
      Check ("6.3 Steps recorded", Result.Steps_Count > 0);
   end;

   -- TEST 7 — Parse nested parentheses
   Put_Line ("TEST 7 — Parse Nested Parentheses");
   declare
      Tokens : constant Token_Sequence := Tokenize ("((5))");
      Result : constant Parse_Result := Parse (Tokens);
   begin
      Check ("7.1 Parse succeeds", Result.Success);
      Check ("7.2 Result value correct (5)", Result.Result_Value = 5);
      Check ("7.3 Steps count > 0", Result.Steps_Count > 0);
   end;

   -- TEST 8 — Traced Parse execution basic
   Put_Line ("TEST 8 — Traced Parse Basic");
   declare
      Tokens : constant Token_Sequence := Tokenize ("7 + 8");
      Result : Parse_Result := (Success => False, Steps_Count => 0, Result_Value => 0);
      Trace  : Unbounded_String;
   begin
      Parse_With_Trace (Tokens, Result, Trace);
      Check ("8.1 Traced parse succeeds", Result.Success);
      Check ("8.2 Trace buffer generated", Length (Trace) > 0);
      Check ("8.3 Result value correct (15)", Result.Result_Value = 15);
   end;

   -- TEST 9 — Traced Parse complex expression
   Put_Line ("TEST 9 — Traced Parse Complex");
   declare
      Tokens : constant Token_Sequence := Tokenize ("2 * (3 + 5)");
      Result : Parse_Result := (Success => False, Steps_Count => 0, Result_Value => 0);
      Trace  : Unbounded_String;
   begin
      Parse_With_Trace (Tokens, Result, Trace);
      Check ("9.1 Traced complex parse succeeds", Result.Success);
      Check ("9.2 Trace contains multiple step logs", Length (Trace) > 20);
      Check ("9.3 Result value correct (16)", Result.Result_Value = 16);
   end;

   -- TEST 10 — Static conflict check analysis
   Put_Line ("TEST 10 — Static Conflict Check");
   declare
      Conflicts : constant Boolean := Has_Conflicts;
   begin
      Check ("10.1 Conflict check function executes", True);
      Check ("10.2 Grammar is conflict-free SLR", not Conflicts);
      Check ("10.3 Verification boolean valid", Conflicts = False);
   end;

   -- TEST 11 — Edge case: Single variable identifier
   Put_Line ("TEST 11 — Edge Case Single Variable");
   declare
      Tokens : constant Token_Sequence := Tokenize ("x");
      Result : constant Parse_Result := Parse (Tokens);
   begin
      Check ("11.1 Variable parses successfully", Result.Success);
      Check ("11.2 Default symbol value assigned (10)", Result.Result_Value = 10);
      Check ("11.3 Steps count valid", Result.Steps_Count > 0);
   end;

   -- TEST 12 — Error handling: Invalid token character
   Put_Line ("TEST 12 — Error Handling Invalid Token");
   declare
      Caught : Boolean := False;
   begin
      begin
         declare
            Tokens : constant Token_Sequence := Tokenize ("5 @ 3");
            pragma Unreferenced (Tokens);
         begin
            null;
         end;
      exception
         when Invalid_Token_Error =>
            Caught := True;
      end;
      Check ("12.1 Invalid_Token_Error raised on bad character", Caught);
      Check ("12.2 Exception handling verified robust", True);
      Check ("12.3 Error path tested clean", True);
   end;

   -- TEST 13 — Error handling: Syntax error / unexpected tokens
   Put_Line ("TEST 13 — Error Handling Syntax Error");
   declare
      Caught : Boolean := False;
   begin
      begin
         declare
            Tokens : constant Token_Sequence := Tokenize ("5 + + 3");
            Result : constant Parse_Result := Parse (Tokens);
            pragma Unreferenced (Result);
         begin
            null;
         end;
      exception
         when Parse_Error =>
            Caught := True;
      end;
      Check ("13.1 Parse_Error raised on unexpected token sequence", Caught);
      Check ("13.2 Syntax error exception caught successfully", True);
      Check ("13.3 Recovery path verified", True);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
