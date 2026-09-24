--  ========================================================================
--  Package Body: Ll_Parser
--  ========================================================================

with Ada.Characters.Handling;

package body Ll_Parser is

   --------------
   -- Tokenize --
   --------------

   function Tokenize (Input : String) return Token_Array is
      Max_Tokens : constant Positive := Positive'Max (1, Input'Length + 1);
      Temp       : Token_Array (1 .. Max_Tokens);
      Count      : Natural := 0;
      I          : Positive := Input'First;
   begin
      while I <= Input'Last loop
         declare
            C : constant Character := Input (I);
         begin
            if Ada.Characters.Handling.Is_Space (C) then
               I := I + 1;
            elsif C in '0' .. '9' then
               declare
                  Val : Integer := 0;
               begin
                  while I <= Input'Last and then Input (I) in '0' .. '9' loop
                     Val := Val * 10 + (Character'Pos (Input (I)) - Character'Pos ('0'));
                     I := I + 1;
                  end loop;
                  Count := Count + 1;
                  Temp (Count) := (Kind => Tok_Num, Val => Val);
               end;
            elsif (C in 'a' .. 'z') or else (C in 'A' .. 'Z') then
               Count := Count + 1;
               Temp (Count) := (Kind => Tok_Id, Name => C);
               I := I + 1;
            elsif C = '+' then
               Count := Count + 1;
               Temp (Count) := (Kind => Tok_Plus);
               I := I + 1;
            elsif C = '*' then
               Count := Count + 1;
               Temp (Count) := (Kind => Tok_Star);
               I := I + 1;
            elsif C = '(' then
               Count := Count + 1;
               Temp (Count) := (Kind => Tok_Lparen);
               I := I + 1;
            elsif C = ')' then
               Count := Count + 1;
               Temp (Count) := (Kind => Tok_Rparen);
               I := I + 1;
            else
               raise Lexical_Error with "Invalid character in input: " & C;
            end if;
         end;
      end loop;

      Count := Count + 1;
      Temp (Count) := (Kind => Tok_Eof);

      return Temp (1 .. Count);
   end Tokenize;

   -----------------------------
   -- Recursive Descent Parser --
   -----------------------------

   function Parse_Recursive_Descent (Tokens : Token_Array) return Integer is
      Index : Positive := Tokens'First;

      function Current_Token return Token is
      begin
         if Index <= Tokens'Last then
            return Tokens (Index);
         else
            return (Kind => Tok_Eof);
         end if;
      end Current_Token;

      procedure Consume (K : Token_Kind) is
      begin
         if Current_Token.Kind = K then
            Index := Index + 1;
         else
            raise Syntax_Error with "Unexpected token in recursive descent parse";
         end if;
      end Consume;

      function Parse_E return Integer;
      function Parse_E_Prime (In_Val : Integer) return Integer;
      function Parse_T return Integer;
      function Parse_T_Prime (In_Val : Integer) return Integer;
      function Parse_F return Integer;

      function Parse_E return Integer is
         Left : Integer;
      begin
         Left := Parse_T;
         return Parse_E_Prime (Left);
      end Parse_E;

      function Parse_E_Prime (In_Val : Integer) return Integer is
      begin
         if Current_Token.Kind = Tok_Plus then
            Consume (Tok_Plus);
            declare
               Right : constant Integer := Parse_T;
            begin
               return Parse_E_Prime (In_Val + Right);
            end;
         else
            return In_Val;
         end if;
      end Parse_E_Prime;

      function Parse_T return Integer is
         Left : Integer;
      begin
         Left := Parse_F;
         return Parse_T_Prime (Left);
      end Parse_T;

      function Parse_T_Prime (In_Val : Integer) return Integer is
      begin
         if Current_Token.Kind = Tok_Star then
            Consume (Tok_Star);
            declare
               Right : constant Integer := Parse_F;
            begin
               return Parse_T_Prime (In_Val * Right);
            end;
         else
            return In_Val;
         end if;
      end Parse_T_Prime;

      function Parse_F return Integer is
         Tok : constant Token := Current_Token;
      begin
         if Tok.Kind = Tok_Num then
            Consume (Tok_Num);
            return Tok.Val;
         elsif Tok.Kind = Tok_Id then
            Consume (Tok_Id);
            return 1;
         elsif Tok.Kind = Tok_Lparen then
            Consume (Tok_Lparen);
            declare
               Val : constant Integer := Parse_E;
            begin
               Consume (Tok_Rparen);
               return Val;
            end;
         else
            raise Syntax_Error with "Syntax error in Parse_F";
         end if;
      end Parse_F;

      Result : Integer;
   begin
      Result := Parse_E;
      if Current_Token.Kind /= Tok_Eof then
         raise Syntax_Error with "Trailing tokens after successful parse";
      end if;
      return Result;
   end Parse_Recursive_Descent;

   --------------------------
   -- Table-Driven Parser ---
   --------------------------

   type Symbol_Type is
     (Sym_E, Sym_E_Prime, Sym_T, Sym_T_Prime, Sym_F,
      Sym_Id, Sym_Num, Sym_Plus, Sym_Star, Sym_Lparen, Sym_Rparen, Sym_Eof);

   function Map_Token_To_Symbol (K : Token_Kind) return Symbol_Type is
   begin
      case K is
         when Tok_Id     => return Sym_Id;
         when Tok_Num    => return Sym_Num;
         when Tok_Plus   => return Sym_Plus;
         when Tok_Star   => return Sym_Star;
         when Tok_Lparen => return Sym_Lparen;
         when Tok_Rparen => return Sym_Rparen;
         when Tok_Eof    => return Sym_Eof;
      end case;
   end Map_Token_To_Symbol;

   function Parse_Table_Driven (Tokens : Token_Array) return Integer is
      Max_Stack : constant Positive := 200;
      Sym_Stack : array (1 .. Max_Stack) of Symbol_Type;
      Sym_Top   : Natural := 0;

      Val_Stack : array (1 .. Max_Stack) of Integer;
      Val_Top   : Natural := 0;

      Tok_Index : Positive := Tokens'First;

      procedure Push_Sym (S : Symbol_Type) is
      begin
         if Sym_Top >= Max_Stack then
             raise Syntax_Error with "Symbol stack overflow";
         end if;
         Sym_Top := Sym_Top + 1;
         Sym_Stack (Sym_Top) := S;
      end Push_Sym;

      procedure Drop_Sym is
      begin
         if Sym_Top = 0 then
            raise Syntax_Error with "Symbol stack underflow";
         end if;
         Sym_Top := Sym_Top - 1;
      end Drop_Sym;

      procedure Push_Val (V : Integer) is
      begin
         if Val_Top >= Max_Stack then
            raise Syntax_Error with "Value stack overflow";
         end if;
         Val_Top := Val_Top + 1;
         Val_Stack (Val_Top) := V;
      end Push_Val;

      Current_Tok : Token;
      Current_Sym : Symbol_Type;
   begin
      Push_Sym (Sym_Eof);
      Push_Sym (Sym_E);

      loop
         if Tok_Index <= Tokens'Last then
            Current_Tok := Tokens (Tok_Index);
         else
            Current_Tok := (Kind => Tok_Eof);
         end if;

         exit when Sym_Top = 0;

         Current_Sym := Sym_Stack (Sym_Top);

         if Current_Sym = Sym_Eof then
            if Current_Tok.Kind = Tok_Eof then
               Drop_Sym;
            else
               raise Syntax_Error with "Expected end of input in table-driven parser";
            end if;
         elsif Current_Sym in Sym_Id .. Sym_Rparen then
            declare
               Expected_Term : constant Symbol_Type := Map_Token_To_Symbol (Current_Tok.Kind);
            begin
               if Current_Sym = Expected_Term then
                  Drop_Sym;
                  if Current_Tok.Kind = Tok_Num then
                     Push_Val (Current_Tok.Val);
                  elsif Current_Tok.Kind = Tok_Id then
                     Push_Val (1);
                  end if;
                  Tok_Index := Tok_Index + 1;
               else
                  raise Syntax_Error with "Terminal mismatch in table-driven parser";
               end if;
            end;
         else
            declare
               T_Sym : constant Symbol_Type := Map_Token_To_Symbol (Current_Tok.Kind);
               Rule  : Natural := 0;
            begin
               case Current_Sym is
                  when Sym_E =>
                     if T_Sym in Sym_Id | Sym_Num | Sym_Lparen then
                        Rule := 1;
                     end if;

                  when Sym_E_Prime =>
                     if T_Sym = Sym_Plus then
                        Rule := 2;
                     elsif T_Sym in Sym_Rparen | Sym_Eof then
                        Rule := 3;
                     end if;

                  when Sym_T =>
                     if T_Sym in Sym_Id | Sym_Num | Sym_Lparen then
                        Rule := 4;
                     end if;

                  when Sym_T_Prime =>
                     if T_Sym in Sym_Plus | Sym_Rparen | Sym_Eof then
                        Rule := 6;
                     elsif T_Sym = Sym_Star then
                        Rule := 5;
                     end if;

                  when Sym_F =>
                     if T_Sym = Sym_Lparen then
                        Rule := 7;
                     elsif T_Sym = Sym_Id then
                        Rule := 8;
                     elsif T_Sym = Sym_Num then
                        Rule := 9;
                     end if;

                  when others =>
                     null;
               end case;

               if Rule = 0 then
                  raise Syntax_Error with "No rule found in LL(1) parsing table";
               end if;

               Drop_Sym;

               case Rule is
                  when 1 =>
                     Push_Sym (Sym_E_Prime);
                     Push_Sym (Sym_T);
                  when 2 =>
                     Push_Sym (Sym_E_Prime);
                     Push_Sym (Sym_T);
                     Push_Sym (Sym_Plus);
                  when 3 =>
                     null;
                  when 4 =>
                     Push_Sym (Sym_T_Prime);
                     Push_Sym (Sym_F);
                  when 5 =>
                     Push_Sym (Sym_T_Prime);
                     Push_Sym (Sym_F);
                     Push_Sym (Sym_Star);
                  when 6 =>
                     null;
                  when 7 =>
                     Push_Sym (Sym_Rparen);
                     Push_Sym (Sym_E);
                     Push_Sym (Sym_Lparen);
                  when 8 =>
                     Push_Sym (Sym_Id);
                  when 9 =>
                     Push_Sym (Sym_Num);
                  when others =>
                     null;
               end case;
            end;
         end if;
      end loop;

      if Val_Top > 0 then
         return Val_Stack (1);
      else
         return 0;
      end if;
   end Parse_Table_Driven;

   --------------------------
   -- Lookahead LL(k) Parser --
   --------------------------

   function Parse_Lookahead_K (Tokens : Token_Array; Lookahead_Depth : Positive := 2) return Integer is
      pragma Unreferenced (Lookahead_Depth);
   begin
      return Parse_Recursive_Descent (Tokens);
   end Parse_Lookahead_K;

end Ll_Parser;
