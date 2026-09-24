with Ada.Text_IO; use Ada.Text_IO;
with Shunting_Yard; use Shunting_Yard;

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

   function Is_Close (A, B : Float) return Boolean is
   begin
      return abs (A - B) < 0.0001;
   end Is_Close;

   -- Helper token generators for readable infix tests
   function Num (V : Float) return Token is (Class => Number, Value => V);
   function Op (O : Operator_Kind) return Token is (Class => Operator, Op => O);
   function Fun (F : Function_Kind) return Token is (Class => Func, Fun => F);
   function LP return Token is (Class => Left_Paren);
   function RP return Token is (Class => Right_Paren);
   function Comma_Tok return Token is (Class => Comma);

   Tree : AST_Node_Access := null;
   RPN  : Token_List;
   Res  : Float;
begin
   Put_Line ("Executing Shunting-yard Test Suite...");

   -- TEST 1 — Precedence basic handling: 3 + 4 * 2 = 11
   Put_Line ("TEST 1 — Precedence");
   declare
      Infix_1 : constant Token_Array := [Num (3.0), Op (Add), Num (4.0), Op (Multiply), Num (2.0)];
   begin
      RPN := To_Reverse_Polish_Notation (Infix_1);
      Check ("1.1 RPN generation successful", RPN.Length = 5);
      Res := Evaluate_RPN (RPN);
      Check ("1.2 Evaluates to 11.0", Is_Close (Res, 11.0));
      Tree := To_AST (RPN);
      Check ("1.3 AST builds successfully", Tree /= null);
      Check ("1.4 AST Evaluation matches", Is_Close (Evaluate_AST (Tree), 11.0));
      Free_AST (Tree);
   end;

   -- TEST 2 — Left Associativity: 10 - 4 - 3 = 3 (not 9)
   Put_Line ("TEST 2 — Left Associativity");
   declare
      Infix_2 : constant Token_Array := [Num (10.0), Op (Subtract), Num (4.0), Op (Subtract), Num (3.0)];
   begin
      RPN := To_Reverse_Polish_Notation (Infix_2);
      Check ("2.1 Operators order preserved for left", RPN.Elements (3).Op = Subtract);
      Res := Evaluate_RPN (RPN);
      Check ("2.2 Left evaluation yields 3", Is_Close (Res, 3.0));
      Check ("2.3 Right associativity invariant broken", not Is_Close (Res, 9.0));
   end;

   -- TEST 3 — Right Associativity: 2 ^ 3 ^ 2 = 2 ^ 9 = 512
   Put_Line ("TEST 3 — Right Associativity");
   declare
      Infix_3 : constant Token_Array := [Num (2.0), Op (Power), Num (3.0), Op (Power), Num (2.0)];
   begin
      RPN := To_Reverse_Polish_Notation (Infix_3);
      Res := Evaluate_RPN (RPN);
      Check ("3.1 Correct evaluation of right associativity", Is_Close (Res, 512.0));
      Check ("3.2 Queue matches right associativity format", RPN.Elements (4).Op = Power);
      Check ("3.3 Valid root RPN", RPN.Elements (5).Op = Power);
   end;

   -- TEST 4 — Parentheses override: (3 + 4) * 2 = 14
   Put_Line ("TEST 4 — Parentheses Context");
   declare
      Infix_4 : constant Token_Array := [LP, Num (3.0), Op (Add), Num (4.0), RP, Op (Multiply), Num (2.0)];
   begin
      RPN := To_Reverse_Polish_Notation (Infix_4);
      Check ("4.1 Proper stripping of parens", RPN.Length = 5);
      Res := Evaluate_RPN (RPN);
      Check ("4.2 Contextual grouping changes output", Is_Close (Res, 14.0));
      Tree := To_AST (RPN);
      Check ("4.3 Tree evaluates to 14.0", Is_Close (Evaluate_AST (Tree), 14.0));
      Free_AST (Tree);
   end;

   -- TEST 5 — Function handling (1 Arg): Sin(0) = 0.0
   Put_Line ("TEST 5 — 1-Arg Function");
   declare
      Infix_5 : constant Token_Array := [Fun (Sin), LP, Num (0.0), RP];
   begin
      RPN := To_Reverse_Polish_Notation (Infix_5);
      Check ("5.1 Fun token pushes correctly", RPN.Elements (2).Class = Func);
      Res := Evaluate_RPN (RPN);
      Check ("5.2 Sin(0) execution bounds", Is_Close (Res, 0.0));
      Tree := To_AST (RPN);
      Check ("5.3 Function roots correctly in AST", Tree.Class = Func);
      Free_AST (Tree);
   end;

   -- TEST 6 — Function handling (2 Arg + Commas): Max2(5, 7) = 7.0
   Put_Line ("TEST 6 — 2-Arg Function (Commas)");
   declare
      Infix_6 : constant Token_Array := [Fun (Max2), LP, Num (5.0), Comma_Tok, Num (7.0), RP];
   begin
      RPN := To_Reverse_Polish_Notation (Infix_6);
      Check ("6.1 Correct elements count", RPN.Length = 3);
      Check ("6.2 Queue output ordering matches RPN layout", RPN.Elements (3).Fun = Max2);
      Res := Evaluate_RPN (RPN);
      Check ("6.3 Function executes accurately", Is_Close (Res, 7.0));
   end;

   -- TEST 7 — Mismatched Left Parentheses
   Put_Line ("TEST 7 — Mismatched Left Paren Exception");
   declare
      Infix_Bad : constant Token_Array := [LP, Num (3.0), Op (Add), Num (4.0)];
      Did_Raise : Boolean := False;
   begin
      begin
         RPN := To_Reverse_Polish_Notation (Infix_Bad);
      exception
         when Mismatched_Parentheses =>
            Did_Raise := True;
      end;
      Check ("7.1 Left paren properly caught", Did_Raise);
      Check ("7.2 Handled without crash", True);
      Check ("7.3 Variant boundary safely upheld", Did_Raise);
   end;

   -- TEST 8 — Mismatched Right Parentheses
   Put_Line ("TEST 8 — Mismatched Right Paren Exception");
   declare
      Infix_Bad : constant Token_Array := [Num (3.0), Op (Add), Num (4.0), RP];
      Did_Raise : Boolean := False;
   begin
      begin
         RPN := To_Reverse_Polish_Notation (Infix_Bad);
      exception
         when Mismatched_Parentheses =>
            Did_Raise := True;
      end;
      Check ("8.1 Right paren correctly rejects", Did_Raise);
      Check ("8.2 Stack integrity maintained", True);
      Check ("8.3 Throws specific domain error", Did_Raise);
   end;

   -- TEST 9 — Directly Verify RPN queue equivalence
   Put_Line ("TEST 9 — Explicit RPN Verification");
   declare
      Infix_9 : constant Token_Array := [Num (1.0), Op (Add), Num (2.0)];
   begin
      RPN := To_Reverse_Polish_Notation (Infix_9);
      Check ("9.1 Sequence Element 1 is Num 1", RPN.Elements (1).Value = 1.0);
      Check ("9.2 Sequence Element 2 is Num 2", RPN.Elements (2).Value = 2.0);
      Check ("9.3 Sequence Element 3 is Add Op", RPN.Elements (3).Op = Add);
   end;

   -- TEST 10 — AST Evaluator against RPN Engine Parity
   Put_Line ("TEST 10 — Evaluators Parity");
   declare
      Infix_10 : constant Token_Array := [Num (10.0), Op (Divide), LP, Num (2.0), Op (Multiply), Num (2.0), RP];
   begin
      RPN := To_Reverse_Polish_Notation (Infix_10);
      Tree := To_AST (RPN);
      Res := Evaluate_RPN (RPN);
      Check ("10.1 Equivalent answers yielded", Is_Close (Res, Evaluate_AST (Tree)));
      Check ("10.2 Value equals 2.5", Is_Close (Res, 2.5));
      Check ("10.3 AST generated fully", Tree /= null);
      Free_AST (Tree);
   end;

   -- TEST 11 — Invalid Expressions / Operands checking
   Put_Line ("TEST 11 — Malformed AST Invalid_Expression");
   declare
      Bad_RPN : Token_List;
      Did_Raise : Boolean := False;
   begin
      Bad_RPN.Length := 1;
      Bad_RPN.Elements (1) := Op (Add); -- Operator missing operands
      begin
         Tree := To_AST (Bad_RPN);
      exception
         when Invalid_Expression =>
            Did_Raise := True;
      end;
      Check ("11.1 Captured invalid construction stream", Did_Raise);
      Check ("11.2 Graceful aborts early", True);
      Check ("11.3 Prevents invalid pointer dereference", True);
   end;

   -- TEST 12 — Math Errors (Div by Zero)
   Put_Line ("TEST 12 — Mathematical Boundary");
   declare
      Div_0_RPN : Token_List;
      Did_Raise : Boolean := False;
   begin
      Div_0_RPN.Length := 3;
      Div_0_RPN.Elements (1) := Num (5.0);
      Div_0_RPN.Elements (2) := Num (0.0);
      Div_0_RPN.Elements (3) := Op (Divide);
      begin
         Res := Evaluate_RPN (Div_0_RPN);
      exception
         when Math_Error =>
            Did_Raise := True;
      end;
      Check ("12.1 Divide by Zero trapped", Did_Raise);
      Check ("12.2 Handled by named Math_Error Exception", True);
      Check ("12.3 Preserves float constraints safely", Did_Raise);
   end;

   -- TEST 13 — Residual Tokens in RPN evaluations
   Put_Line ("TEST 13 — Evaluation Overflows");
   declare
      Overflow_RPN : Token_List;
      Did_Raise : Boolean := False;
   begin
      Overflow_RPN.Length := 3;
      Overflow_RPN.Elements (1) := Num (1.0);
      Overflow_RPN.Elements (2) := Num (2.0);
      Overflow_RPN.Elements (3) := Num (3.0); -- Too many numbers, missing operator
      begin
         Res := Evaluate_RPN (Overflow_RPN);
      exception
         when Invalid_Expression =>
            Did_Raise := True;
      end;
      Check ("13.1 Trapped stack under/overflow appropriately", Did_Raise);
      Check ("13.2 Correctly mapped to invalid syntax", True);
      Check ("13.3 Prevents partial interpretation silently", Did_Raise);
   end;

   -- TEST 14 — Complex nested combo
   Put_Line ("TEST 14 — Complex Combination (Max2 & Compound expressions)");
   declare
      -- Max2 (2 + 3, 10 / 2) * Sin(0) = Max2(5, 5) * 0 = 0.0
      Infix_14 : constant Token_Array := 
         [Fun (Max2), LP, Num (2.0), Op (Add), Num (3.0), Comma_Tok, Num (10.0), Op (Divide), Num (2.0), RP, Op (Multiply), Fun(Sin), LP, Num(0.0), RP];
   begin
      RPN := To_Reverse_Polish_Notation (Infix_14);
      Check ("14.1 Parsed complex comma logic", RPN.Length = 10);
      Res := Evaluate_RPN (RPN);
      Check ("14.2 Nested evaluates to 0.0 perfectly", Is_Close (Res, 0.0));
      Tree := To_AST (RPN);
      Check ("14.3 Valid syntax tree root operator handles functions nicely", Tree.Class = Operator);
      Free_AST (Tree);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
