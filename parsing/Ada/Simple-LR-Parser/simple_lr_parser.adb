--------------------------------------------------------------------------------
-- Package Body: Simple_LR_Parser
--------------------------------------------------------------------------------

with Ada.Characters.Handling;

package body Simple_LR_Parser is

   -- Helper: convert Token_Kind to column index in Action table
   -- Terminals: 0: id, 1: +, 2: *, 3: (, 4: ), 5: $
   type Terminal_Index is range 0 .. 5;

   function To_Terminal_Index (Kind : Token_Kind) return Terminal_Index is
   begin
      case Kind is
         when Tok_Id      => return 0;
         when Tok_Plus    => return 1;
         when Tok_Star    => return 2;
         when Tok_L_Paren => return 3;
         when Tok_R_Paren => return 4;
         when Tok_Eof     => return 5;
      end case;
   end To_Terminal_Index;

   -- Nonterminals: 0: E, 1: T, 2: F
   type Nonterminal_Index is range 0 .. 2;

   function To_Nonterminal_Index (Sym : String) return Nonterminal_Index is
   begin
      if Sym = "E" then
         return 0;
      elsif Sym = "T" then
         return 1;
      else
         return 2;
      end if;
   end To_Nonterminal_Index;

   -- SLR Action Table lookup
   -- States 0..12 (using State_ID range 0..15)
   function Get_Action (State : State_ID; Term : Terminal_Index) return Parse_Action is
   begin
      -- Hardcoded canonical SLR action table for expression grammar
      case State is
         when 0 =>
            case Term is
               when 0 => return (Act_Shift, 5);  -- id -> shift 5
               when 3 => return (Act_Shift, 4);  -- ( -> shift 4
               when others => return (Act_Error, 0);
            end case;
         when 1 =>
            case Term is
               when 1 => return (Act_Shift, 6);  -- + -> shift 6
               when 5 => return (Act_Accept, 0); -- $ -> accept
               when others => return (Act_Error, 0);
            end case;
         when 2 =>
            case Term is
               when 1 => return (Act_Reduce, 2); -- + -> reduce E -> T
               when 2 => return (Act_Shift, 7);  -- * -> shift 7
               when 4 => return (Act_Reduce, 2); -- ) -> reduce E -> T
               when 5 => return (Act_Reduce, 2); -- $ -> reduce E -> T
               when others => return (Act_Error, 0);
            end case;
         when 3 =>
            case Term is
               when 1 => return (Act_Reduce, 4); -- + -> reduce T -> F
               when 2 => return (Act_Reduce, 4); -- * -> reduce T -> F
               when 4 => return (Act_Reduce, 4); -- ) -> reduce T -> F
               when 5 => return (Act_Reduce, 4); -- $ -> reduce T -> F
               when others => return (Act_Error, 0);
            end case;
         when 4 =>
            case Term is
               when 0 => return (Act_Shift, 5);  -- id -> shift 5
               when 3 => return (Act_Shift, 4);  -- ( -> shift 4
               when others => return (Act_Error, 0);
            end case;
         when 5 =>
            case Term is
               when 1 => return (Act_Reduce, 6); -- + -> reduce F -> id
               when 2 => return (Act_Reduce, 6); -- * -> reduce F -> id
               when 4 => return (Act_Reduce, 6); -- ) -> reduce F -> id
               when 5 => return (Act_Reduce, 6); -- $ -> reduce F -> id
               when others => return (Act_Error, 0);
            end case;
         when 6 =>
            case Term is
               when 0 => return (Act_Shift, 5);  -- id -> shift 5
               when 3 => return (Act_Shift, 4);  -- ( -> shift 4
               when others => return (Act_Error, 0);
            end case;
         when 7 =>
            case Term is
               when 0 => return (Act_Shift, 5);  -- id -> shift 5
               when 3 => return (Act_Shift, 4);  -- ( -> shift 4
               when others => return (Act_Error, 0);
            end case;
         when 8 =>
            case Term is
               when 1 => return (Act_Shift, 6);  -- + -> shift 6
               when 4 => return (Act_Shift, 9);  -- ) -> shift 9
               when others => return (Act_Error, 0);
            end case;
         when 9 =>
            case Term is
               when 1 => return (Act_Reduce, 5); -- + -> reduce F -> ( E )
               when 2 => return (Act_Reduce, 5); -- * -> reduce F -> ( E )
               when 4 => return (Act_Reduce, 5); -- ) -> reduce F -> ( E )
               when 5 => return (Act_Reduce, 5); -- $ -> reduce F -> ( E )
               when others => return (Act_Error, 0);
            end case;
         when 10 =>
            case Term is
               when 1 => return (Act_Reduce, 1); -- + -> reduce E -> E + T
               when 2 => return (Act_Shift, 7);  -- * -> shift 7
               when 4 => return (Act_Reduce, 1); -- ) -> reduce E -> E + T
               when 5 => return (Act_Reduce, 1); -- $ -> reduce E -> E + T
               when others => return (Act_Error, 0);
            end case;
         when 11 =>
            case Term is
               when 1 => return (Act_Reduce, 3); -- + -> reduce T -> T * F
               when 2 => return (Act_Reduce, 3); -- * -> reduce T -> T * F
               when 4 => return (Act_Reduce, 3); -- ) -> reduce T -> T * F
               when 5 => return (Act_Reduce, 3); -- $ -> reduce T -> T * F
               when others => return (Act_Error, 0);
            end case;
         when others =>
            return (Act_Error, 0);
      end case;
   end Get_Action;

   -- SLR Goto Table lookup
   function Get_Goto (State : State_ID; Nonterm : Nonterminal_Index) return State_ID is
   begin
      case State is
         when 0 =>
            case Nonterm is
               when 0 => return 1;  -- E -> 1
               when 1 => return 2;  -- T -> 2
               when 2 => return 3;  -- F -> 3
            end case;
         when 4 =>
            case Nonterm is
               when 0 => return 8;  -- E -> 8
               when 1 => return 2;  -- T -> 2
               when 2 => return 3;  -- F -> 3
            end case;
         when 6 =>
            case Nonterm is
               when 1 => return 10; -- T -> 10
               when 2 => return 3;  -- F -> 3
               when others => return 0;
            end case;
         when 7 =>
            case Nonterm is
               when 2 => return 11; -- F -> 11
               when others => return 0;
            end case;
         when others =>
            return 0;
      end case;
   end Get_Goto;

   -- Tokenizer implementation
   function Tokenize (Text : String) return Token_Sequence is
      Result : Token_Sequence;
      I      : Positive := Text'First;
      Lexeme_Str : Ada.Strings.Unbounded.Unbounded_String;
      Num_Val    : Integer;
   begin
      while I <= Text'Last loop
         -- Skip whitespace
         if Text (I) = ' ' or else Text (I) = ASCII.HT or else Text (I) = ASCII.LF or else Text (I) = ASCII.CR then
            I := I + 1;
         elsif Text (I) = '+' then
            Result.Append (Token_Rec'(Kind => Tok_Plus, Lexeme => Ada.Strings.Unbounded.To_Unbounded_String ("+"), Value => 0));
            I := I + 1;
         elsif Text (I) = '*' then
            Result.Append (Token_Rec'(Kind => Tok_Star, Lexeme => Ada.Strings.Unbounded.To_Unbounded_String ("*"), Value => 0));
            I := I + 1;
         elsif Text (I) = '(' then
            Result.Append (Token_Rec'(Kind => Tok_L_Paren, Lexeme => Ada.Strings.Unbounded.To_Unbounded_String ("("), Value => 0));
            I := I + 1;
         elsif Text (I) = ')' then
            Result.Append (Token_Rec'(Kind => Tok_R_Paren, Lexeme => Ada.Strings.Unbounded.To_Unbounded_String (")"), Value => 0));
            I := I + 1;
         elsif Ada.Characters.Handling.Is_Digit (Text (I)) or else Ada.Characters.Handling.Is_Letter (Text (I)) then
            declare
               Start_Idx : constant Positive := I;
            begin
               while I <= Text'Last and then (Ada.Characters.Handling.Is_Alphanumeric (Text (I)) or else Text (I) = '_') loop
                  I := I + 1;
               end loop;
               Lexeme_Str := Ada.Strings.Unbounded.To_Unbounded_String (Text (Start_Idx .. I - 1));
               begin
                  Num_Val := Integer'Value (Ada.Strings.Unbounded.To_String (Lexeme_Str));
               exception
                  when others =>
                     Num_Val := 10; -- Default symbolic value for identifiers
               end;
               Result.Append (Token_Rec'(Kind => Tok_Id, Lexeme => Lexeme_Str, Value => Num_Val));
            end;
         else
            raise Invalid_Token_Error with "Unexpected character in input: " & Text (I);
         end if;
      end loop;

      -- Append EOF marker
      Result.Append (Token_Rec'(Kind => Tok_Eof, Lexeme => Ada.Strings.Unbounded.To_Unbounded_String ("$"), Value => 0));
      return Result;
   end Tokenize;

   -- Core parser implementation supporting both standard and traced execution
   procedure Execute_Parse
     (Input        : Token_Sequence;
      Res          : out Parse_Result;
      Traced       : Boolean;
      Trace_Buf    : out Ada.Strings.Unbounded.Unbounded_String)
   is
      package State_Vectors is new Ada.Containers.Vectors
        (Index_Type   => Positive,
         Element_Type => State_ID);

      package Value_Vectors is new Ada.Containers.Vectors
        (Index_Type   => Positive,
         Element_Type => Integer);

      State_Stack : State_Vectors.Vector;
      Value_Stack : Value_Vectors.Vector;
      Token_Idx   : Positive := 1;
      Steps       : Natural := 0;
      Current_Tok : Token_Rec;
      Action      : Parse_Action;
      Done        : Boolean := False;
   begin
      Trace_Buf := Ada.Strings.Unbounded.Null_Unbounded_String;
      State_Stack.Append (0);
      Value_Stack.Append (0);

      while not Done loop
         if Token_Idx > Natural (Input.Length) then
            raise Parse_Error with "Unexpected end of input stream";
         end if;

         Current_Tok := Input.Element (Token_Idx);

         declare
            Top_State : constant State_ID := State_Stack.Last_Element;
            Term_Idx  : constant Terminal_Index := To_Terminal_Index (Current_Tok.Kind);
         begin
            Action := Get_Action (Top_State, Term_Idx);

            if Traced then
               Ada.Strings.Unbounded.Append
                 (Trace_Buf,
                  "State: " & State_ID'Image (Top_State) &
                  " | Token: " & Token_Kind'Image (Current_Tok.Kind) &
                  " | Action: " & Action_Type'Image (Action.Kind) &
                  Integer'Image (Action.Value) & ASCII.LF);
            end if;

            case Action.Kind is
               when Act_Shift =>
                  State_Stack.Append (State_ID (Action.Value));
                  Value_Stack.Append (Current_Tok.Value);
                  Token_Idx := Token_Idx + 1;
                  Steps := Steps + 1;

               when Act_Reduce =>
                  declare
                     R_ID : constant Rule_ID := Rule_ID (Action.Value);
                     Val  : Integer := 0;
                  begin
                     case R_ID is
                        when 0 =>
                           null;
                        when 1 => -- E -> E + T
                           declare
                              Val_T : constant Integer := Value_Stack.Last_Element;
                           begin
                              Value_Stack.Delete_Last;
                              Value_Stack.Delete_Last;
                              declare
                                 Val_E : constant Integer := Value_Stack.Last_Element;
                              begin
                                 Value_Stack.Delete_Last;
                                 Val := Val_E + Val_T;
                              end;
                           end;
                           for I in 1 .. 3 loop
                              State_Stack.Delete_Last;
                           end loop;

                        when 2 => -- E -> T
                           Val := Value_Stack.Last_Element;
                           Value_Stack.Delete_Last;
                           State_Stack.Delete_Last;

                        when 3 => -- T -> T * F
                           declare
                              Val_F : constant Integer := Value_Stack.Last_Element;
                           begin
                              Value_Stack.Delete_Last;
                              Value_Stack.Delete_Last;
                              declare
                                 Val_T : constant Integer := Value_Stack.Last_Element;
                              begin
                                 Value_Stack.Delete_Last;
                                 Val := Val_T * Val_F;
                              end;
                           end;
                           for I in 1 .. 3 loop
                              State_Stack.Delete_Last;
                           end loop;

                        when 4 => -- T -> F
                           Val := Value_Stack.Last_Element;
                           Value_Stack.Delete_Last;
                           State_Stack.Delete_Last;

                        when 5 => -- F -> ( E )
                           Value_Stack.Delete_Last;
                           Val := Value_Stack.Last_Element;
                           Value_Stack.Delete_Last;
                           Value_Stack.Delete_Last;
                           for I in 1 .. 3 loop
                              State_Stack.Delete_Last;
                           end loop;

                        when 6 => -- F -> id
                           Val := Value_Stack.Last_Element;
                           Value_Stack.Delete_Last;
                           State_Stack.Delete_Last;
                     end case;

                     declare
                        New_Top_State : constant State_ID := State_Stack.Last_Element;
                        Lhs_Nonterm   : Nonterminal_Index := 0;
                     begin
                        if R_ID = 1 or else R_ID = 2 then
                           Lhs_Nonterm := To_Nonterminal_Index ("E");
                        elsif R_ID = 3 or else R_ID = 4 then
                           Lhs_Nonterm := To_Nonterminal_Index ("T");
                        else
                           Lhs_Nonterm := To_Nonterminal_Index ("F");
                        end if;

                        declare
                           Next_State : constant State_ID := Get_Goto (New_Top_State, Lhs_Nonterm);
                        begin
                           if Next_State = 0 and then New_Top_State /= 0 then
                              raise Parse_Error with "Invalid GOTO transition";
                           end if;
                           State_Stack.Append (Next_State);
                           Value_Stack.Append (Val);
                        end;
                     end;
                     Steps := Steps + 1;
                  end;

               when Act_Accept =>
                  Res := (Success      => True,
                          Steps_Count  => Steps,
                          Result_Value => Value_Stack.Last_Element);
                  Done := True;

               when Act_Error =>
                  raise Parse_Error with "Syntax error encountered during SLR parse at token " &
                    Token_Kind'Image (Current_Tok.Kind);
            end case;
         end;
      end loop;
   exception
      when others =>
         Res := (Success => False, Steps_Count => Steps, Result_Value => 0);
         raise;
   end Execute_Parse;

   -- Public Parse
   function Parse (Input : Token_Sequence) return Parse_Result is
      Res   : Parse_Result;
      Trace : Ada.Strings.Unbounded.Unbounded_String;
   begin
      Execute_Parse (Input, Res, False, Trace);
      return Res;
   end Parse;

   -- Public Parse_With_Trace
   procedure Parse_With_Trace
     (Input        : Token_Sequence;
      Result       : out Parse_Result;
      Trace_Buffer : out Ada.Strings.Unbounded.Unbounded_String)
   is
   begin
      Execute_Parse (Input, Result, True, Trace_Buffer);
   end Parse_With_Trace;

   -- Static conflict check based on grammar definition
   function Has_Conflicts return Boolean is
   begin
      return False;
   end Has_Conflicts;

end Simple_LR_Parser;
