package body Operator_Precedence_Parser is

   --  Returns True if the token is a standard mathematical operator
   function Is_Operator (Kind : Token_Kind) return Boolean is
     (Kind in Tk_Plus | Tk_Minus | Tk_Multiply | Tk_Divide | Tk_Power);

   --  Defines precedence levels (higher number = tighter binding)
   function Get_Precedence (Kind : Token_Kind) return Precedence_Level is
   begin
      case Kind is
         when Tk_Plus | Tk_Minus     => return 1;
         when Tk_Multiply | Tk_Divide => return 2;
         when Tk_Power               => return 3;
         when others                 =>
            raise Program_Error with "Not an operator";
      end case;
   end Get_Precedence;

   --  Defines associativity rules for operators
   function Get_Associativity (Kind : Token_Kind) return Associativity_Type is
   begin
      case Kind is
         when Tk_Plus | Tk_Minus | Tk_Multiply | Tk_Divide =>
            return Assoc_Left;
         when Tk_Power =>
            return Assoc_Right;
         when others =>
            raise Program_Error with "Not an operator";
      end case;
   end Get_Associativity;

   --  Core mathematical evaluation
   function Apply_Operator (Op : Token_Kind; Left, Right : Value_Type) return Value_Type is
   begin
      case Op is
         when Tk_Plus     => return Left + Right;
         when Tk_Minus    => return Left - Right;
         when Tk_Multiply => return Left * Right;
         when Tk_Divide   =>
            if Right = 0 then
               raise Parse_Error with "Division by zero";
            end if;
            return Left / Right;
         when Tk_Power    =>
            if Right < 0 then
               raise Parse_Error with "Negative exponent unsupported";
            end if;
            return Left ** Natural (Right);
         when others      =>
            raise Parse_Error with "Invalid operator execution";
      end case;
   exception
      when Constraint_Error =>
         raise Parse_Error with "Mathematical overflow";
   end Apply_Operator;

   --  Lexical analysis implementation
   function Lex (Input : String) return Token_Array is
      Result : Token_Array (1 .. Input'Length + 1);
      Count  : Natural := 0;
      Idx    : Positive := Input'First;

      procedure Add (T : Token_Type) is
      begin
         Count := Count + 1;
         Result (Count) := T;
      end Add;
   begin
      while Idx <= Input'Last loop
         case Input (Idx) is
            when ' ' | ASCII.HT | ASCII.CR | ASCII.LF =>
               Idx := Idx + 1;
            when '+' => Add (Token_Type'(Kind => Tk_Plus));        Idx := Idx + 1;
            when '-' => Add (Token_Type'(Kind => Tk_Minus));       Idx := Idx + 1;
            when '*' => Add (Token_Type'(Kind => Tk_Multiply));    Idx := Idx + 1;
            when '/' => Add (Token_Type'(Kind => Tk_Divide));      Idx := Idx + 1;
            when '^' => Add (Token_Type'(Kind => Tk_Power));       Idx := Idx + 1;
            when '(' => Add (Token_Type'(Kind => Tk_Left_Paren));  Idx := Idx + 1;
            when ')' => Add (Token_Type'(Kind => Tk_Right_Paren)); Idx := Idx + 1;
            when '0' .. '9' =>
               declare
                  Val : Value_Type := 0;
               begin
                  while Idx <= Input'Last and then Input (Idx) in '0' .. '9' loop
                     Val := Val * 10 + Value_Type (Character'Pos (Input (Idx)) - Character'Pos ('0'));
                     Idx := Idx + 1;
                  end loop;
                  Add (Token_Type'(Kind => Tk_Number, Value => Val));
               exception
                  when Constraint_Error =>
                     raise Lex_Error with "Number too large";
               end;
            when others =>
               raise Lex_Error with "Invalid character encountered: '" & Input (Idx) & "'";
         end case;
      end loop;
      Add (Token_Type'(Kind => Tk_End));
      return Result (1 .. Count);
   end Lex;

   -----------------------------------------------------------------------------
   --  Variant 1: Precedence Climbing
   -----------------------------------------------------------------------------
   function Evaluate_Precedence_Climbing (Tokens : Token_Array) return Value_Type is
      Index : Positive := Tokens'First;

      function Parse_Expression (Min_Prec : Precedence_Level) return Value_Type;
      function Parse_Primary return Value_Type;

      function Parse_Primary return Value_Type is
         Result : Value_Type;
      begin
         if Index > Tokens'Last or else Tokens (Index).Kind = Tk_End then
            raise Parse_Error with "Unexpected end of input in primary expression";
         end if;

         if Tokens (Index).Kind = Tk_Number then
            Result := Tokens (Index).Value;
            Index := Index + 1;
            return Result;
         elsif Tokens (Index).Kind = Tk_Left_Paren then
            Index := Index + 1;
            Result := Parse_Expression (0);
            if Index > Tokens'Last or else Tokens (Index).Kind /= Tk_Right_Paren then
               raise Parse_Error with "Missing right parenthesis";
            end if;
            Index := Index + 1;
            return Result;
         else
            raise Parse_Error with "Unexpected token: expected number or '('";
         end if;
      end Parse_Primary;

      function Parse_Expression (Min_Prec : Precedence_Level) return Value_Type is
         Lhs         : Value_Type;
         Op          : Token_Kind;
         Prec        : Precedence_Level;
         Assoc       : Associativity_Type;
         Next_Min_Pr : Precedence_Level;
         Rhs         : Value_Type;
      begin
         Lhs := Parse_Primary;

         while Index <= Tokens'Last and then Is_Operator (Tokens (Index).Kind) loop
            Op := Tokens (Index).Kind;
            Prec := Get_Precedence (Op);

            if Prec < Min_Prec then
               exit;
            end if;

            Assoc := Get_Associativity (Op);
            if Assoc = Assoc_Left then
               Next_Min_Pr := Prec + 1;
            else
               Next_Min_Pr := Prec;
            end if;

            Index := Index + 1;
            Rhs := Parse_Expression (Next_Min_Pr);
            Lhs := Apply_Operator (Op, Lhs, Rhs);
         end loop;

         return Lhs;
      end Parse_Expression;

      Final_Result : constant Value_Type := Parse_Expression (0);
   begin
      if Tokens (Index).Kind /= Tk_End then
         raise Parse_Error with "Unexpected trailing tokens";
      end if;
      return Final_Result;
   end Evaluate_Precedence_Climbing;


   -----------------------------------------------------------------------------
   --  Variant 2: Dijkstra's Shunting-Yard
   -----------------------------------------------------------------------------
   function Evaluate_Shunting_Yard (Tokens : Token_Array) return Value_Type is
      --  Internal stacks bounded safely by the maximum possible token count
      Val_Stack : array (1 .. Tokens'Length) of Value_Type;
      Val_Top   : Natural := 0;

      Op_Stack  : array (1 .. Tokens'Length) of Token_Kind;
      Op_Top    : Natural := 0;

      procedure Push_Val (V : Value_Type) is
      begin
         Val_Top := Val_Top + 1;
         Val_Stack (Val_Top) := V;
      end Push_Val;

      function Pop_Val return Value_Type is
         Result : Value_Type;
      begin
         if Val_Top = 0 then
            raise Parse_Error with "Missing operand";
         end if;
         Result := Val_Stack (Val_Top);
         Val_Top := Val_Top - 1;
         return Result;
      end Pop_Val;

      procedure Push_Op (Op : Token_Kind) is
      begin
         Op_Top := Op_Top + 1;
         Op_Stack (Op_Top) := Op;
      end Push_Op;

      function Pop_Op return Token_Kind is
         Result : Token_Kind;
      begin
         if Op_Top = 0 then
            raise Parse_Error with "Mismatched parentheses or missing operator";
         end if;
         Result := Op_Stack (Op_Top);
         Op_Top := Op_Top - 1;
         return Result;
      end Pop_Op;

      procedure Apply_Top_Op is
         Op    : constant Token_Kind := Pop_Op;
         Right : constant Value_Type := Pop_Val;
         Left  : constant Value_Type := Pop_Val;
      begin
         Push_Val (Apply_Operator (Op, Left, Right));
      end Apply_Top_Op;

   begin
      for I in Tokens'Range loop
         declare
            --  Declaring Tok as a constant proves its discriminant won't change
            --  satisfying the compiler's safety checks for variant record access.
            Tok : constant Token_Type := Tokens (I);
         begin
            case Tok.Kind is
               when Tk_Number =>
                  Push_Val (Tok.Value);

               when Tk_Left_Paren =>
                  Push_Op (Tok.Kind);

               when Tk_Right_Paren =>
                  while Op_Top > 0 and then Op_Stack (Op_Top) /= Tk_Left_Paren loop
                     Apply_Top_Op;
                  end loop;
                  if Op_Top = 0 then
                     raise Parse_Error with "Mismatched right parenthesis";
                  end if;
                  declare
                     Discard : constant Token_Kind := Pop_Op;
                  begin
                     null; -- Safely discard the left parenthesis
                  end;

               when Tk_Plus | Tk_Minus | Tk_Multiply | Tk_Divide | Tk_Power =>
                  declare
                     Cur_Prec  : constant Precedence_Level   := Get_Precedence (Tok.Kind);
                     Cur_Assoc : constant Associativity_Type := Get_Associativity (Tok.Kind);
                     Top_Prec  : Precedence_Level;
                  begin
                     while Op_Top > 0 and then Op_Stack (Op_Top) /= Tk_Left_Paren loop
                        Top_Prec := Get_Precedence (Op_Stack (Op_Top));
                        if (Cur_Assoc = Assoc_Left and then Top_Prec >= Cur_Prec) or else
                           (Cur_Assoc = Assoc_Right and then Top_Prec > Cur_Prec)
                        then
                           Apply_Top_Op;
                        else
                           exit;
                        end if;
                     end loop;
                  end;
                  Push_Op (Tok.Kind);

               when Tk_End =>
                  while Op_Top > 0 loop
                     if Op_Stack (Op_Top) = Tk_Left_Paren then
                        raise Parse_Error with "Mismatched left parenthesis";
                     end if;
                     Apply_Top_Op;
                  end loop;
            end case;
         end;
      end loop;

      if Val_Top /= 1 then
         raise Parse_Error with "Invalid expression format";
      end if;

      return Pop_Val;
   end Evaluate_Shunting_Yard;

end Operator_Precedence_Parser;
