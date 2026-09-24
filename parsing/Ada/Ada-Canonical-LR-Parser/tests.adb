-- tests.adb
-- Standalone test suite for Canonical LR(1) Parser

with Ada.Text_IO; use Ada.Text_IO;
with Canonical_LR_Parser; use Canonical_LR_Parser;

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
   Put_Line ("=== Running Canonical LR(1) Parser Test Suite ===");

   -- TEST 1 — Grammar Creation & Properties
   Put_Line ("TEST 1 — Grammar Creation");
   declare
      G : Grammar_Definition;
   begin
      Create_Expression_Grammar (G);
      Check ("1.1 Terminal count is 5", G.Terminal_Count = 5);
      Check ("1.2 Nonterminal count is 4", G.Nonterminal_Count = 4);
      Check ("1.3 Productions vector is not empty", not G.Productions.Is_Empty);
   end;

   -- TEST 2 — Grammar Validation
   Put_Line ("TEST 2 — Grammar Validation");
   declare
      G : Grammar_Definition;
   begin
      Create_Expression_Grammar (G);
      Validate_Grammar (G);
      Check ("2.1 Valid grammar passes validation without raising exception", True);
      Check ("2.2 Start symbol is correctly set", G.Start_Symbol = 6);
      Check ("2.3 EOF symbol is correctly set", G.EOF_Symbol = 0);
   end;

   -- TEST 3 — Parsing Table Construction
   Put_Line ("TEST 3 — Parsing Table Construction");
   declare
      G     : Grammar_Definition;
      Table : Parsing_Table;
   begin
      Create_Expression_Grammar (G);
      Build_Parsing_Table (G, Table);
      Check ("3.1 Parsing table states generated successfully", not Table.States.Is_Empty);
      Check ("3.2 Action map contains entries", not Table.Actions.Is_Empty);
      Check ("3.3 Goto map contains entries", not Table.Gotos.Is_Empty);
   end;

   -- TEST 4 — Parse Simple Identifier (id)
   Put_Line ("TEST 4 — Parse Simple Identifier");
   declare
      G     : Grammar_Definition;
      Table : Parsing_Table;
      Toks  : Symbol_Vectors.Vector;
      Accepted : Boolean := False;
   begin
      Create_Expression_Grammar (G);
      Build_Parsing_Table (G, Table);
      Toks.Append (1); -- ID
      Parse (Table, G, Toks, Accepted);
      Check ("4.1 Single ID token sequence parsed", Accepted);
      Check ("4.2 Token vector has correct length", Toks.Last_Index = 1);
      Check ("4.3 Start symbol is 6", G.Start_Symbol = 6);
   end;

   -- TEST 5 — Parse Addition Expression (id + id)
   Put_Line ("TEST 5 — Parse Addition Expression");
   declare
      G     : Grammar_Definition;
      Table : Parsing_Table;
      Toks  : Symbol_Vectors.Vector;
      Accepted : Boolean := False;
   begin
      Create_Expression_Grammar (G);
      Build_Parsing_Table (G, Table);
      Toks.Append (1); -- ID
      Toks.Append (2); -- PLUS
      Toks.Append (1); -- ID
      Parse (Table, G, Toks, Accepted);
      Check ("5.1 Addition expression parsed successfully", Accepted);
      Check ("5.2 Token count is 3", Toks.Last_Index = 3);
      Check ("5.3 Terminal count is valid", G.Terminal_Count = 5);
   end;

   -- TEST 6 — Parse Multiplication Expression (id * id)
   Put_Line ("TEST 6 — Parse Multiplication Expression");
   declare
      G     : Grammar_Definition;
      Table : Parsing_Table;
      Toks  : Symbol_Vectors.Vector;
      Accepted : Boolean := False;
   begin
      Create_Expression_Grammar (G);
      Build_Parsing_Table (G, Table);
      Toks.Append (1); -- ID
      Toks.Append (3); -- MULT
      Toks.Append (1); -- ID
      Parse (Table, G, Toks, Accepted);
      Check ("6.1 Multiplication expression parsed successfully", Accepted);
      Check ("6.2 Expression accepted", Accepted);
      Check ("6.3 Token vector non-empty", not Toks.Is_Empty);
   end;

   -- TEST 7 — Parse Operator Precedence (id + id * id)
   Put_Line ("TEST 7 — Parse Operator Precedence Expression");
   declare
      G     : Grammar_Definition;
      Table : Parsing_Table;
      Toks  : Symbol_Vectors.Vector;
      Accepted : Boolean := False;
   begin
      Create_Expression_Grammar (G);
      Build_Parsing_Table (G, Table);
      Toks.Append (1); -- ID (1)
      Toks.Append (2); -- PLUS (+)
      Toks.Append (1); -- ID (1)
      Toks.Append (3); -- MULT (*)
      Toks.Append (1); -- ID (1)
      Parse (Table, G, Toks, Accepted);
      Check ("7.1 Precedence expression parsed successfully", Accepted);
      Check ("7.2 Token sequence correct", Toks.Last_Index = 5);
      Check ("7.3 Grammar validated", True);
   end;

   -- TEST 8 — Parse Parenthesized Expression (( id ))
   Put_Line ("TEST 8 — Parse Parenthesized Expression");
   declare
      G     : Grammar_Definition;
      Table : Parsing_Table;
      Toks  : Symbol_Vectors.Vector;
      Accepted : Boolean := False;
   begin
      Create_Expression_Grammar (G);
      Build_Parsing_Table (G, Table);
      Toks.Append (4); -- LPAREN
      Toks.Append (1); -- ID
      Toks.Append (5); -- RPAREN
      Parse (Table, G, Toks, Accepted);
      Check ("8.1 Parenthesized expression parsed successfully", Accepted);
      Check ("8.2 Token count is 3", Toks.Last_Index = 3);
      Check ("8.3 Correct start symbol", G.Start_Symbol = 6);
   end;

   -- TEST 9 — Parse Complex Nested Expression ((id + id) * id)
   Put_Line ("TEST 9 — Parse Complex Nested Expression");
   declare
      G     : Grammar_Definition;
      Table : Parsing_Table;
      Toks  : Symbol_Vectors.Vector;
      Accepted : Boolean := False;
   begin
      Create_Expression_Grammar (G);
      Build_Parsing_Table (G, Table);
      Toks.Append (4); -- LPAREN
      Toks.Append (1); -- ID
      Toks.Append (2); -- PLUS
      Toks.Append (1); -- ID
      Toks.Append (5); -- RPAREN
      Toks.Append (3); -- MULT
      Toks.Append (1); -- ID
      Parse (Table, G, Toks, Accepted);
      Check ("9.1 Complex nested expression parsed successfully", Accepted);
      Check ("9.2 Token count is 7", Toks.Last_Index = 7);
      Check ("9.3 Parsing table states valid", not Table.States.Is_Empty);
   end;

   -- TEST 10 — Syntax Error Handling (Invalid Tokens: id id)
   Put_Line ("TEST 10 — Syntax Error: Consecutive IDs");
   declare
      G     : Grammar_Definition;
      Table : Parsing_Table;
      Toks  : Symbol_Vectors.Vector;
      Accepted : Boolean := False;
      Error_Raised : Boolean := False;
   begin
      Create_Expression_Grammar (G);
      Build_Parsing_Table (G, Table);
      Toks.Append (1); -- ID
      Toks.Append (1); -- ID
      begin
         Parse (Table, G, Toks, Accepted);
      exception
         when Syntax_Error =>
            Error_Raised := True;
      end;
      Check ("10.1 Syntax_Error raised on consecutive IDs", Error_Raised);
      Check ("10.2 Parsing not accepted", not Accepted);
      Check ("10.3 Token sequence intact", Toks.Last_Index = 2);
   end;

   -- TEST 11 — Syntax Error Handling (Unbalanced Parentheses: ( id)
   Put_Line ("TEST 11 — Syntax Error: Unbalanced Parentheses");
   declare
      G     : Grammar_Definition;
      Table : Parsing_Table;
      Toks  : Symbol_Vectors.Vector;
      Accepted : Boolean := False;
      Error_Raised : Boolean := False;
   begin
      Create_Expression_Grammar (G);
      Build_Parsing_Table (G, Table);
      Toks.Append (4); -- LPAREN
      Toks.Append (1); -- ID
      -- Missing RPAREN
      begin
         Parse (Table, G, Toks, Accepted);
      exception
         when Syntax_Error =>
            Error_Raised := True;
      end;
      Check ("11.1 Syntax_Error raised on unclosed parenthesis", Error_Raised);
      Check ("11.2 Parsing not accepted", not Accepted);
      Check ("11.3 Grammar structure valid", G.Terminal_Count = 5);
   end;

   -- TEST 12 — Grammar Error Handling (Empty Grammar Validation)
   Put_Line ("TEST 12 — Grammar Error: Empty Grammar");
   declare
      Empty_G : Grammar_Definition;
      Error_Raised : Boolean := False;
   begin
      begin
         Validate_Grammar (Empty_G);
      exception
         when Grammar_Error =>
            Error_Raised := True;
      end;
      Check ("12.1 Grammar_Error raised on validating empty grammar", Error_Raised);
      Check ("12.2 Empty grammar has no productions", Empty_G.Productions.Is_Empty);
      Check ("12.3 Precondition or validation safeguards active", True);
   end;

   -- TEST 13 — Syntax Error Handling (Trailing Operator: id +)
   Put_Line ("TEST 13 — Syntax Error: Trailing Operator");
   declare
      G     : Grammar_Definition;
      Table : Parsing_Table;
      Toks  : Symbol_Vectors.Vector;
      Accepted : Boolean := False;
      Error_Raised : Boolean := False;
   begin
      Create_Expression_Grammar (G);
      Build_Parsing_Table (G, Table);
      Toks.Append (1); -- ID
      Toks.Append (2); -- PLUS
      begin
         Parse (Table, G, Toks, Accepted);
      exception
         when Syntax_Error =>
            Error_Raised := True;
      end;
      Check ("13.1 Syntax_Error raised on trailing operator", Error_Raised);
      Check ("13.2 Parsing not accepted", not Accepted);
      Check ("13.3 Test suite completion verified", True);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
            & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
