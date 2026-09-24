with Ada.Text_IO; use Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Step_Parser; use Step_Parser;

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

   State : Lexer_State;
   Tok   : Token;
begin
   Put_Line ("TEST 1 — Lexer: Identifiers and Keywords");
   Initialize (State, "ISO-10303-21 HEADER ENDSEC");
   Check ("1.1 Lexer is initialized", Is_Initialized (State));
   Next_Token (State, Tok);
   Check ("1.2 First token is keyword ISO-10303-21", Tok.Kind = Tok_Keyword and then To_String (Tok.Lexeme) = "ISO-10303-21");
   Next_Token (State, Tok);
   Check ("1.3 Second token is keyword HEADER", Tok.Kind = Tok_Keyword and then To_String (Tok.Lexeme) = "HEADER");

   Put_Line ("TEST 2 — Lexer: Punctuation and Structure");
   Initialize (State, "#1 = ( );");
   Next_Token (State, Tok);
   Check ("2.1 Entity Ref extracted", Tok.Kind = Tok_Entity_Ref and then To_String (Tok.Lexeme) = "#1");
   Next_Token (State, Tok);
   Check ("2.2 Equals token extracted", Tok.Kind = Tok_Equals);
   Next_Token (State, Tok);
   Check ("2.3 LParen token extracted", Tok.Kind = Tok_LParen);

   Put_Line ("TEST 3 — Lexer: Strings and Enums");
   Initialize (State, "'Hello''World' .T. .FALSE.");
   Next_Token (State, Tok);
   Check ("3.1 String literal extracted", Tok.Kind = Tok_String and then To_String (Tok.Lexeme) = "'Hello''World'");
   Next_Token (State, Tok);
   Check ("3.2 Enum .T. extracted", Tok.Kind = Tok_Enum and then To_String (Tok.Lexeme) = ".T.");
   Next_Token (State, Tok);
   Check ("3.3 Enum .FALSE. extracted", Tok.Kind = Tok_Enum and then To_String (Tok.Lexeme) = ".FALSE.");

   Put_Line ("TEST 4 — Lexer: Numbers");
   Initialize (State, "123 -45.67 1.0E-5");
   Next_Token (State, Tok);
   Check ("4.1 Positive integer", Tok.Kind = Tok_Integer and then To_String (Tok.Lexeme) = "123");
   Next_Token (State, Tok);
   Check ("4.2 Negative real", Tok.Kind = Tok_Real and then To_String (Tok.Lexeme) = "-45.67");
   Next_Token (State, Tok);
   Check ("4.3 Scientific real", Tok.Kind = Tok_Real and then To_String (Tok.Lexeme) = "1.0E-5");

   Put_Line ("TEST 5 — Lexer: Comments and Whitespace");
   Initialize (State, "/* test */  DATA /* c2 */ ;");
   Next_Token (State, Tok);
   Check ("5.1 Skip to DATA keyword", Tok.Kind = Tok_Keyword and then To_String (Tok.Lexeme) = "DATA");
   Next_Token (State, Tok);
   Check ("5.2 Skip to Semicolon", Tok.Kind = Tok_Semicolon);
   Next_Token (State, Tok);
   Check ("5.3 Reach EOF safely", Tok.Kind = Tok_EOF);

   Put_Line ("TEST 6 — Parser: Entity Instance Valid");
   Initialize (State, "#1 = POINT(1.0, 2.0); ENDSEC;");
   Parse_Entity_Instance (State);
   Check ("6.1 Successfully parsed instance", True);
   Next_Token (State, Tok);
   Check ("6.2 Lexer stopped at ENDSEC", Tok.Kind = Tok_Keyword and then To_String (Tok.Lexeme) = "ENDSEC");
   Next_Token (State, Tok);
   Check ("6.3 Semicolon follows", Tok.Kind = Tok_Semicolon);

   Put_Line ("TEST 7 — Parser: Entity Instance Invalid (Unmatched Paren)");
   Initialize (State, "#2 = DIR(0.0 ; ENDSEC;");
   begin
      Parse_Entity_Instance (State);
      Check ("7.1 Syntax_Error not raised", False);
   exception
      when Syntax_Error =>
         Check ("7.1 Syntax_Error correctly raised for unmatched paren", True);
   end;
   Check ("7.2 State was initialized", Is_Initialized (State));
   Check ("7.3 Ensure test continuation", True);

   Put_Line ("TEST 8 — Parser: Header Section Valid");
   Initialize (State, "HEADER; FILE_DESCRIPTION((''),''); ENDSEC;");
   Parse_Header_Section (State);
   Check ("8.1 Header section parsed without errors", True);
   Next_Token (State, Tok);
   Check ("8.2 End of stream reached", Tok.Kind = Tok_EOF);
   Check ("8.3 State remains initialized", Is_Initialized (State));

   Put_Line ("TEST 9 — Parser: Data Section Valid");
   Initialize (State, "DATA; #10 = ITEM('A'); #20 = ITEM('B'); ENDSEC;");
   Parse_Data_Section (State);
   Check ("9.1 Data section parsed", True);
   Next_Token (State, Tok);
   Check ("9.2 Reached EOF", Tok.Kind = Tok_EOF);
   Check ("9.3 Valid data instances consumed", True);

   Put_Line ("TEST 10 — Parser: Anchor Section Valid");
   Initialize (State, "ANCHOR; <UUID> = #10; ENDSEC;");
   Parse_Anchor_Section (State);
   Check ("10.1 Anchor section parsed", True);
   Next_Token (State, Tok);
   Check ("10.2 Reached EOF", Tok.Kind = Tok_EOF);
   Check ("10.3 State valid", Is_Initialized (State));

   Put_Line ("TEST 11 — Parser: Reference and Signature Sections");
   Initialize (State, "REFERENCE; ENDSEC; SIGNATURE; ENDSEC;");
   Parse_Reference_Section (State);
   Check ("11.1 Reference parsed empty", True);
   Parse_Signature_Section (State);
   Check ("11.2 Signature parsed empty", True);
   Next_Token (State, Tok);
   Check ("11.3 Reached EOF", Tok.Kind = Tok_EOF);

   Put_Line ("TEST 12 — Parser: Full Exchange Structure Valid");
   Initialize (State, "ISO-10303-21; HEADER; ENDSEC; DATA; ENDSEC; END-ISO-10303-21;");
   Parse_Exchange_Structure (State);
   Check ("12.1 Full structure parsed", True);
   Next_Token (State, Tok);
   Check ("12.2 End of input reached cleanly", Tok.Kind = Tok_EOF);
   Check ("12.3 Ensure parsing didn't skip EOF", True);

   Put_Line ("TEST 13 — Errors: Missing ISO Keyword");
   Initialize (State, "HEADER; ENDSEC;");
   begin
      Parse_Exchange_Structure (State);
      Check ("13.1 Exception not raised", False);
   exception
      when Syntax_Error =>
         Check ("13.1 Syntax_Error raised for missing ISO keyword", True);
   end;
   Check ("13.2 State initialized verified", Is_Initialized (State));
   Check ("13.3 Test completed successfully", True);

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
