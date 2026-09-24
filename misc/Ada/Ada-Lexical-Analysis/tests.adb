pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings.Fixed;

with Lexical_Analysis; use Lexical_Analysis;

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

   Tok : Token;
begin
   Put_Line ("=== Executing Lexical Analysis Test Suite ===");
   Put_Line ("");

   -- TEST 1 - Eager Tokenization Basic Variant
   Put_Line ("TEST 1 — Eager Tokenization Basic Variant");
   declare
      Res : constant Token_Array := Tokenize_Eager ("x = 1;");
   begin
      Check ("1.1 Result length is 5 (4 tokens + EOF)", Res'Length = 5);
      Check ("1.2 First token is Identifier", Res(Res'First).Kind = Tk_Identifier);
      Check ("1.3 Last token is EOF", Res(Res'Last).Kind = Tk_End_Of_Input);
   end;

   -- TEST 2 - Lazy Lexer Initialization & First Token Variant
   Put_Line ("TEST 2 — Lazy Lexer Initialization Variant");
   declare
      L : Lexer := Initialize ("if (x)");
   begin
      Check ("2.1 Init completes without exception", True);
      Next_Token (L, Tok);
      Check ("2.2 First token is Keyword 'if'", Tok.Kind = Tk_Keyword);
      Check ("2.3 Token starts at Line 1", Tok.Line = 1);
   end;

   -- TEST 3 - Maximal Munch Strategy (Operators)
   Put_Line ("TEST 3 — Maximal Munch Strategy (Operators)");
   declare
      L : Lexer := Initialize ("<=");
   begin
      Next_Token (L, Tok);
      Check ("3.1 '<=' is parsed as a single operator", Tok.Kind = Tk_Operator);
      Check ("3.2 Text length is 2", Length (Tok.Text) = 2);
      Check ("3.3 Text is exactly '<='", To_String (Tok.Text) = "<=");
   end;

   -- TEST 4 - Non-Maximal Munch / Adjacent Separated Operators
   Put_Line ("TEST 4 — Adjacent Separated Operators");
   declare
      L : Lexer := Initialize ("< =");
   begin
      Next_Token (L, Tok);
      Check ("4.1 First token is operator '<'", Tok.Kind = Tk_Operator and then To_String (Tok.Text) = "<");
      Next_Token (L, Tok);
      Check ("4.2 Second token is operator '='", Tok.Kind = Tk_Operator and then To_String (Tok.Text) = "=");
      Check ("4.3 Parsed as strictly separated operators", Length(Tok.Text) = 1);
   end;

   -- TEST 5 - Keywords vs Identifiers Resolution
   Put_Line ("TEST 5 — Keywords vs Identifiers Resolution");
   declare
      L : Lexer := Initialize ("return returnValue");
   begin
      Next_Token (L, Tok);
      Check ("5.1 'return' is identified as Tk_Keyword", Tok.Kind = Tk_Keyword);
      Next_Token (L, Tok);
      Check ("5.2 'returnValue' is correctly Tk_Identifier", Tok.Kind = Tk_Identifier);
      Check ("5.3 Correct lexeme textual value extracted", To_String (Tok.Text) = "returnValue");
   end;

   -- TEST 6 - Integer Literal Tokenization
   Put_Line ("TEST 6 — Integer Literal Tokenization");
   declare
      L : Lexer := Initialize ("42 0");
   begin
      Next_Token (L, Tok);
      Check ("6.1 '42' is classified Tk_Integer_Literal", Tok.Kind = Tk_Integer_Literal);
      Check ("6.2 Lexeme matches '42'", To_String (Tok.Text) = "42");
      Next_Token (L, Tok);
      Check ("6.3 '0' is classified correctly as integer", Tok.Kind = Tk_Integer_Literal and then To_String (Tok.Text) = "0");
   end;

   -- TEST 7 - Punctuation Handling
   Put_Line ("TEST 7 — Punctuation Handling");
   declare
      L : Lexer := Initialize ("();,");
   begin
      Next_Token (L, Tok);
      Check ("7.1 '(' is Tk_Punctuation", Tok.Kind = Tk_Punctuation and then To_String (Tok.Text) = "(");
      Next_Token (L, Tok);
      Check ("7.2 ')' is Tk_Punctuation", Tok.Kind = Tk_Punctuation and then To_String (Tok.Text) = ")");
      Next_Token (L, Tok);
      Next_Token (L, Tok);
      Check ("7.3 ',' is Tk_Punctuation", Tok.Kind = Tk_Punctuation and then To_String (Tok.Text) = ",");
   end;

   -- TEST 8 - Two-Phase Explicit API (Scanner & Evaluator separation)
   Put_Line ("TEST 8 — Two-Phase Explicit API Separation");
   declare
      Input_Str : constant String := "  while";
      S_Start   : Positive;
      S_End     : Natural;
   begin
      Extract_Lexeme (Input_Str, Input_Str'First, S_Start, S_End);
      Check ("8.1 Scanner identifies start strictly after spaces", S_Start = 3);
      Check ("8.2 Scanner identifies end at end of string", S_End = 7);
      declare
         Ev_Tok : constant Token := Evaluate_Lexeme (Input_Str, S_Start, S_End, 1, 3);
      begin
         Check ("8.3 Evaluator successfully maps text to Tk_Keyword", Ev_Tok.Kind = Tk_Keyword);
      end;
   end;

   -- TEST 9 - Line and Column Tracking Across Newlines
   Put_Line ("TEST 9 — Line and Column Tracking");
   declare
      L : Lexer := Initialize ("a" & ASCII.LF & " b" & ASCII.LF & "  c");
   begin
      Next_Token (L, Tok);
      Check ("9.1 'a' is Line 1, Col 1", Tok.Line = 1 and Tok.Column = 1);
      Next_Token (L, Tok);
      Check ("9.2 'b' is Line 2, Col 2", Tok.Line = 2 and Tok.Column = 2);
      Next_Token (L, Tok);
      Check ("9.3 'c' is Line 3, Col 3", Tok.Line = 3 and Tok.Column = 3);
   end;

   -- TEST 10 - End of Input Invariants
   Put_Line ("TEST 10 — End of Input Invariants");
   declare
      L : Lexer := Initialize (" ");
   begin
      Next_Token (L, Tok);
      Check ("10.1 First token on whitespace string is EOF", Tok.Kind = Tk_End_Of_Input);
      Check ("10.2 Text of EOF token is an empty string", Length (Tok.Text) = 0);
      Next_Token (L, Tok);
      Check ("10.3 Subsequent calls still securely return EOF", Tok.Kind = Tk_End_Of_Input);
   end;

   -- TEST 11 - Error/Unknown Character Handling
   Put_Line ("TEST 11 — Error/Unknown Character Handling");
   declare
      L : Lexer := Initialize ("@#");
   begin
      Next_Token (L, Tok);
      Check ("11.1 '@' gracefully yields Tk_Error", Tok.Kind = Tk_Error);
      Check ("11.2 Text payload is '@'", To_String (Tok.Text) = "@");
      Next_Token (L, Tok);
      Check ("11.3 '#' gracefully yields Tk_Error", Tok.Kind = Tk_Error and then To_String (Tok.Text) = "#");
   end;

   -- TEST 12 - Empty Input String Eager Check
   Put_Line ("TEST 12 — Empty Input String Handling");
   declare
      Res : constant Token_Array := Tokenize_Eager ("");
   begin
      Check ("12.1 Array length safely collapses to 1 (just EOF)", Res'Length = 1);
      Check ("12.2 Single element is definitely EOF", Res(Res'First).Kind = Tk_End_Of_Input);
      Check ("12.3 Line and Col safely default to 1", Res(Res'First).Line = 1 and Res(Res'First).Column = 1);
   end;

   -- TEST 13 - To_String Formatting Helper
   Put_Line ("TEST 13 — To_String Helper Output formatting");
   declare
      Ev_Tok : Token;
   begin
      Ev_Tok.Kind   := Tk_Identifier;
      Ev_Tok.Text   := To_Unbounded_String ("var");
      Ev_Tok.Line   := 5;
      Ev_Tok.Column := 12;
      declare
         Str : constant String := Lexical_Analysis.To_String (Ev_Tok);
      begin
         Check ("13.1 Formatted string embeds accurate Tk_Kind", 
                Ada.Strings.Fixed.Index (Str, "TK_IDENTIFIER") > 0);
         Check ("13.2 Formatted string embeds exact Lexeme", 
                Ada.Strings.Fixed.Index (Str, "var") > 0);
         Check ("13.3 Output cleanly formatted with line/col", 
                Ada.Strings.Fixed.Index (Str, "5:12") > 0);
      end;
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
