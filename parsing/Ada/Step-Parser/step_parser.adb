with Ada.Characters.Handling; use Ada.Characters.Handling;

package body Step_Parser is

   use Ada.Strings.Unbounded;

   ----------------------------------------------------------------------------
   -- Helper Functions
   ----------------------------------------------------------------------------

   function Is_Initialized (State : Lexer_State) return Boolean is
   begin
      return State.Initialized;
   end Is_Initialized;

   procedure Initialize (State : out Lexer_State; Input : String) is
   begin
      State.Input       := To_Unbounded_String (Input);
      State.Cursor      := 1;
      State.Line        := 1;
      State.Col         := 1;
      State.Initialized := True;
      State.Has_Cached  := False;
   end Initialize;

   -- Advance cursor and update Line/Col trackers
   procedure Advance (State : in out Lexer_State) is
      C : Character;
   begin
      if State.Cursor <= Length (State.Input) then
         C := Element (State.Input, State.Cursor);
         if C = ASCII.LF then
            State.Line := State.Line + 1;
            State.Col  := 1;
         else
            State.Col := State.Col + 1;
         end if;
         State.Cursor := State.Cursor + 1;
      end if;
   end Advance;

   -- Extract tokens
   procedure Fetch_Next (State : in out Lexer_State; Tok : out Token) is
      C : Character;
      Start_Cursor : Positive;
   begin
      Tok.Kind := Tok_None;
      Tok.Lexeme := Null_Unbounded_String;

      loop
         if State.Cursor > Length (State.Input) then
            Tok.Kind := Tok_EOF;
            Tok.Line := State.Line;
            Tok.Col  := State.Col;
            return;
         end if;

         C := Element (State.Input, State.Cursor);

         -- Skip Whitespace
         if C = ' ' or else C = ASCII.HT or else C = ASCII.CR or else C = ASCII.LF then
            Advance (State);

         -- Skip Comments /* ... */
         elsif C = '/' and then State.Cursor + 1 <= Length (State.Input)
           and then Element (State.Input, State.Cursor + 1) = '*'
         then
            Advance (State); -- Consume '/'
            Advance (State); -- Consume '*'
            loop
               if State.Cursor > Length (State.Input) then
                  raise Syntax_Error with "Unterminated comment";
               end if;
               if Element (State.Input, State.Cursor) = '*'
                 and then State.Cursor + 1 <= Length (State.Input)
                 and then Element (State.Input, State.Cursor + 1) = '/'
               then
                  Advance (State);
                  Advance (State);
                  exit;
               end if;
               Advance (State);
            end loop;
         else
            exit; -- Found start of a token
         end if;
      end loop;

      Tok.Line := State.Line;
      Tok.Col  := State.Col;
      Start_Cursor := State.Cursor;

      -- Entity Reference (#123)
      if C = '#' then
         Advance (State);
         while State.Cursor <= Length (State.Input) and then Is_Digit (Element (State.Input, State.Cursor)) loop
            Advance (State);
         end loop;
         Tok.Kind := Tok_Entity_Ref;
         Tok.Lexeme := To_Unbounded_String (Slice (State.Input, Start_Cursor, State.Cursor - 1));
         return;
      end if;

      -- String Literal ('...')
      if C = ''' then
         Advance (State);
         loop
            if State.Cursor > Length (State.Input) then
               raise Syntax_Error with "Unterminated string literal";
            end if;
            C := Element (State.Input, State.Cursor);
            Advance (State);
            if C = ''' then
               if State.Cursor <= Length (State.Input) and then Element (State.Input, State.Cursor) = ''' then
                  Advance (State); -- Escaped quote ''
               else
                  exit; -- End of string
               end if;
            end if;
         end loop;
         Tok.Kind := Tok_String;
         Tok.Lexeme := To_Unbounded_String (Slice (State.Input, Start_Cursor, State.Cursor - 1));
         return;
      end if;

      -- Identifiers and Keywords
      if Is_Letter (C) or else C = '_' then
         while State.Cursor <= Length (State.Input) loop
            C := Element (State.Input, State.Cursor);
            if Is_Alphanumeric (C) or else C = '_' or else C = '-' then
               Advance (State);
            else
               exit;
            end if;
         end loop;
         Tok.Lexeme := To_Unbounded_String (Slice (State.Input, Start_Cursor, State.Cursor - 1));
         declare
            Upper_Str : constant String := To_Upper (To_String (Tok.Lexeme));
         begin
            if Upper_Str = "ISO-10303-21" or else Upper_Str = "END-ISO-10303-21" or else
               Upper_Str = "HEADER" or else Upper_Str = "ENDSEC" or else Upper_Str = "DATA" or else
               Upper_Str = "ANCHOR" or else Upper_Str = "REFERENCE" or else Upper_Str = "SIGNATURE"
            then
               Tok.Kind := Tok_Keyword;
            else
               Tok.Kind := Tok_Identifier;
            end if;
         end;
         return;
      end if;

      -- Enum (.T., .F., .UNKNOWN.) or Real starting with '.'
      if C = '.' then
         Advance (State);
         if State.Cursor <= Length (State.Input) and then Is_Letter (Element (State.Input, State.Cursor)) then
            while State.Cursor <= Length (State.Input) and then Element (State.Input, State.Cursor) /= '.' loop
               Advance (State);
            end loop;
            if State.Cursor > Length (State.Input) then
               raise Syntax_Error with "Unterminated enum literal";
            end if;
            Advance (State); -- Consume closing '.'
            Tok.Kind := Tok_Enum;
            Tok.Lexeme := To_Unbounded_String (Slice (State.Input, Start_Cursor, State.Cursor - 1));
            return;
         end if;
         -- Fallthrough for Reals starting with '.' is possible but standard requires leading digit.
      end if;

      -- Numbers (Integer or Real)
      if Is_Digit (C) or else C = '+' or else C = '-' then
         Advance (State);
         while State.Cursor <= Length (State.Input) and then Is_Digit (Element (State.Input, State.Cursor)) loop
            Advance (State);
         end loop;
         
         if State.Cursor <= Length (State.Input) and then Element (State.Input, State.Cursor) = '.' then
            Advance (State);
            while State.Cursor <= Length (State.Input) and then Is_Digit (Element (State.Input, State.Cursor)) loop
               Advance (State);
            end loop;
            Tok.Kind := Tok_Real;
         else
            Tok.Kind := Tok_Integer;
         end if;
         
         if State.Cursor <= Length (State.Input) and then 
            (Element (State.Input, State.Cursor) = 'E' or else Element (State.Input, State.Cursor) = 'e') 
         then
            Advance (State);
            if State.Cursor <= Length (State.Input) and then 
               (Element (State.Input, State.Cursor) = '+' or else Element (State.Input, State.Cursor) = '-') 
            then
               Advance (State);
            end if;
            while State.Cursor <= Length (State.Input) and then Is_Digit (Element (State.Input, State.Cursor)) loop
               Advance (State);
            end loop;
            Tok.Kind := Tok_Real;
         end if;
         Tok.Lexeme := To_Unbounded_String (Slice (State.Input, Start_Cursor, State.Cursor - 1));
         return;
      end if;

      -- Punctuation
      Advance (State);
      Tok.Lexeme := To_Unbounded_String (String'(1 => C));
      case C is
         when '(' => Tok.Kind := Tok_LParen;
         when ')' => Tok.Kind := Tok_RParen;
         when ',' => Tok.Kind := Tok_Comma;
         when ';' => Tok.Kind := Tok_Semicolon;
         when '=' => Tok.Kind := Tok_Equals;
         when '*' => Tok.Kind := Tok_Asterisk;
         when '$' => Tok.Kind := Tok_Dollar;
         when '<' => Tok.Kind := Tok_Less;
         when '>' => Tok.Kind := Tok_Greater;
         when others => 
            raise Syntax_Error with "Unexpected character: " & C;
      end case;

   end Fetch_Next;

   procedure Next_Token (State : in out Lexer_State; Tok : out Token) is
   begin
      if State.Has_Cached then
         Tok := State.Cached;
         State.Has_Cached := False;
      else
         Fetch_Next (State, Tok);
      end if;
   end Next_Token;

   procedure Peek_Token (State : in out Lexer_State; Tok : out Token) is
   begin
      if not State.Has_Cached then
         Fetch_Next (State, State.Cached);
         State.Has_Cached := True;
      end if;
      Tok := State.Cached;
   end Peek_Token;

   procedure Consume_Specific (State : in out Lexer_State; Expected : Token_Kind) is
      Tok : Token;
   begin
      Next_Token (State, Tok);
      if Tok.Kind /= Expected then
         raise Syntax_Error with "Unexpected token. Expected " & Expected'Image & " got " & Tok.Kind'Image;
      end if;
   end Consume_Specific;

   ----------------------------------------------------------------------------
   -- Parser Implementation
   ----------------------------------------------------------------------------

   procedure Parse_Entity_Instance (State : in out Lexer_State) is
      Tok   : Token;
      Depth : Paren_Count := 0;
   begin
      loop
         Peek_Token (State, Tok);
         if Tok.Kind = Tok_EOF then
            raise Unexpected_End_Of_File with "Entity instance truncated";
         end if;
         if Tok.Kind = Tok_Keyword and then To_Upper (To_String (Tok.Lexeme)) = "ENDSEC" then
            return; -- Caller will handle ENDSEC
         end if;

         Next_Token (State, Tok);

         if Tok.Kind = Tok_LParen then
            Depth := Depth + 1;
         elsif Tok.Kind = Tok_RParen then
            if Depth = 0 then
               raise Syntax_Error with "Unmatched closing parenthesis";
            end if;
            Depth := Depth - 1;
         elsif Tok.Kind = Tok_Semicolon then
            if Depth = 0 then
               return; -- Successfully consumed one instance definition up to semicolon
            else
               raise Syntax_Error with "Semicolon encountered inside parentheses";
            end if;
         end if;
      end loop;
   end Parse_Entity_Instance;

   procedure Parse_Generic_Section (State : in out Lexer_State; Expected_Name : String) is
      Tok : Token;
   begin
      Next_Token (State, Tok);
      if Tok.Kind /= Tok_Keyword or else To_Upper (To_String (Tok.Lexeme)) /= Expected_Name then
         raise Syntax_Error with "Expected section " & Expected_Name;
      end if;
      Consume_Specific (State, Tok_Semicolon);

      loop
         Peek_Token (State, Tok);
         if Tok.Kind = Tok_EOF then
            raise Unexpected_End_Of_File with "Missing ENDSEC for " & Expected_Name;
         end if;

         if Tok.Kind = Tok_Keyword and then To_Upper (To_String (Tok.Lexeme)) = "ENDSEC" then
            Next_Token (State, Tok); -- Consume ENDSEC
            Consume_Specific (State, Tok_Semicolon);
            return;
         end if;

         Parse_Entity_Instance (State);
      end loop;
   end Parse_Generic_Section;

   procedure Parse_Header_Section (State : in out Lexer_State) is
   begin
      Parse_Generic_Section (State, "HEADER");
   end Parse_Header_Section;

   procedure Parse_Data_Section (State : in out Lexer_State) is
   begin
      Parse_Generic_Section (State, "DATA");
   end Parse_Data_Section;

   procedure Parse_Anchor_Section (State : in out Lexer_State) is
   begin
      Parse_Generic_Section (State, "ANCHOR");
   end Parse_Anchor_Section;

   procedure Parse_Reference_Section (State : in out Lexer_State) is
   begin
      Parse_Generic_Section (State, "REFERENCE");
   end Parse_Reference_Section;

   procedure Parse_Signature_Section (State : in out Lexer_State) is
   begin
      Parse_Generic_Section (State, "SIGNATURE");
   end Parse_Signature_Section;

   procedure Parse_Exchange_Structure (State : in out Lexer_State) is
      Tok : Token;
   begin
      -- Parse ISO-10303-21;
      Next_Token (State, Tok);
      if Tok.Kind /= Tok_Keyword or else To_Upper (To_String (Tok.Lexeme)) /= "ISO-10303-21" then
         raise Syntax_Error with "Missing ISO-10303-21 keyword";
      end if;
      Consume_Specific (State, Tok_Semicolon);

      -- Must have a HEADER section
      Parse_Header_Section (State);

      -- Optional Sections (Ed 3) and mandatory DATA section
      loop
         Peek_Token (State, Tok);
         if Tok.Kind = Tok_Keyword then
            declare
               Upper_Str : constant String := To_Upper (To_String (Tok.Lexeme));
            begin
               if Upper_Str = "ANCHOR" then
                  Parse_Anchor_Section (State);
               elsif Upper_Str = "REFERENCE" then
                  Parse_Reference_Section (State);
               elsif Upper_Str = "SIGNATURE" then
                  Parse_Signature_Section (State);
               elsif Upper_Str = "DATA" then
                  Parse_Data_Section (State);
               elsif Upper_Str = "END-ISO-10303-21" then
                  exit; -- Data section might be optional in some contexts, or we are done
               else
                  raise Syntax_Error with "Unexpected section keyword: " & Upper_Str;
               end if;
            end;
         else
            raise Syntax_Error with "Expected section keyword or END-ISO-10303-21";
         end if;
      end loop;

      -- Parse END-ISO-10303-21;
      Next_Token (State, Tok);
      Consume_Specific (State, Tok_Semicolon);
   end Parse_Exchange_Structure;

end Step_Parser;
