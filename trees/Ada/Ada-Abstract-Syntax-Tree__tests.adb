pragma Assertion_Policy (Check);

with Ada.Text_IO; use Ada.Text_IO;
with Abstract_Syntax_Tree; use Abstract_Syntax_Tree;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS - " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL - " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   Env : Environment := [others => 0];
   Node, Left, Right : AST_Node_Access;
   Raised : Boolean;
begin
   -- TEST 1 - Literals
   Put_Line ("TEST 1 - Literals");
   Node := Create_Literal (42);
   Check ("1.1 Literal Evaluate", Evaluate (Node, Env) = 42);
   Check ("1.2 Literal String", To_String (Node) = "42");
   Check ("1.3 Literal Count", Node_Count (Node) = 1);
   Check ("1.4 Literal Depth", Tree_Depth (Node) = 1);
   Free_Tree (Node);
   Check ("1.5 Freed Literal is null", Node = null);

   -- TEST 2 - Variables
   Put_Line ("TEST 2 - Variables");
   Env := [others => 0];
   Env (Char_To_Var ('X')) := 15;
   Node := Create_Variable (Char_To_Var ('X'));
   Check ("2.1 Variable Evaluate", Evaluate (Node, Env) = 15);
   Check ("2.2 Variable String", To_String (Node) = "X");
   Check ("2.3 Variable Count", Node_Count (Node) = 1);
   Check ("2.4 Variable Depth", Tree_Depth (Node) = 1);
   Free_Tree (Node);

   -- TEST 3 - Unary Operation (Negation)
   Put_Line ("TEST 3 - Unary Operation (Negation)");
   Node := Create_Unary (Op_Neg, Create_Literal (10));
   Check ("3.1 Unary Evaluate", Evaluate (Node, Env) = -10);
   Check ("3.2 Unary String", To_String (Node) = "(-10)");
   Check ("3.3 Unary Count", Node_Count (Node) = 2);
   Check ("3.4 Unary Depth", Tree_Depth (Node) = 2);
   Free_Tree (Node);

   -- TEST 4 - Binary Operation: Addition
   Put_Line ("TEST 4 - Binary Operation: Addition");
   Node := Create_Binary (Op_Add, Create_Literal (3), Create_Literal (7));
   Check ("4.1 Add Evaluate", Evaluate (Node, Env) = 10);
   Check ("4.2 Add String", To_String (Node) = "(3 + 7)");
   Check ("4.3 Add Count", Node_Count (Node) = 3);
   Check ("4.4 Add Depth", Tree_Depth (Node) = 2);
   Free_Tree (Node);

   -- TEST 5 - Binary Operation: Subtraction
   Put_Line ("TEST 5 - Binary Operation: Subtraction");
   Node := Create_Binary (Op_Sub, Create_Literal (10), Create_Literal (4));
   Check ("5.1 Sub Evaluate", Evaluate (Node, Env) = 6);
   Check ("5.2 Sub String", To_String (Node) = "(10 - 4)");
   Check ("5.3 Sub Count", Node_Count (Node) = 3);
   Free_Tree (Node);

   -- TEST 6 - Binary Operation: Multiplication
   Put_Line ("TEST 6 - Binary Operation: Multiplication");
   Node := Create_Binary (Op_Mul, Create_Literal (6), Create_Literal (7));
   Check ("6.1 Mul Evaluate", Evaluate (Node, Env) = 42);
   Check ("6.2 Mul String", To_String (Node) = "(6 * 7)");
   Check ("6.3 Mul Depth", Tree_Depth (Node) = 2);
   Free_Tree (Node);

   -- TEST 7 - Binary Operation: Division
   Put_Line ("TEST 7 - Binary Operation: Division");
   Node := Create_Binary (Op_Div, Create_Literal (20), Create_Literal (4));
   Check ("7.1 Div Evaluate exact", Evaluate (Node, Env) = 5);
   Check ("7.2 Div String", To_String (Node) = "(20 / 4)");
   Check ("7.3 Div Count", Node_Count (Node) = 3);
   Free_Tree (Node);

   -- TEST 8 - Complex Expression: (A + B) * C
   Put_Line ("TEST 8 - Complex Expression: (A + B) * C");
   Env := [others => 0];
   Env (Char_To_Var ('A')) := 2;
   Env (Char_To_Var ('B')) := 3;
   Env (Char_To_Var ('C')) := 4;
   Left := Create_Binary (Op_Add, Create_Variable (Char_To_Var ('A')), Create_Variable (Char_To_Var ('B')));
   Right := Create_Variable (Char_To_Var ('C'));
   Node := Create_Binary (Op_Mul, Left, Right);
   Check ("8.1 Expr1 Evaluate is 20", Evaluate (Node, Env) = 20);
   Check ("8.2 Expr1 String", To_String (Node) = "((A + B) * C)");
   Check ("8.3 Expr1 Count", Node_Count (Node) = 5);
   Check ("8.4 Expr1 Depth", Tree_Depth (Node) = 3);
   Free_Tree (Node);

   -- TEST 9 - Complex Expression: -(A + 5)
   Put_Line ("TEST 9 - Complex Expression: -(A + 5)");
   Env := [others => 0];
   Env (Char_To_Var ('A')) := 5;
   Node := Create_Unary (Op_Neg, Create_Binary (Op_Add, Create_Variable (Char_To_Var ('A')), Create_Literal (5)));
   Check ("9.1 Expr2 Evaluate is -10", Evaluate (Node, Env) = -10);
   Check ("9.2 Expr2 String", To_String (Node) = "(-(A + 5))");
   Check ("9.3 Expr2 Count", Node_Count (Node) = 4);
   Check ("9.4 Expr2 Depth", Tree_Depth (Node) = 3);
   Free_Tree (Node);

   -- TEST 10 - Division By Zero Edge Cases
   Put_Line ("TEST 10 - Division By Zero Edge Cases");
   Env := [others => 0];
   
   -- 10.1
   Node := Create_Binary (Op_Div, Create_Literal (5), Create_Literal (0));
   Raised := False;
   begin
      if Evaluate (Node, Env) = 0 then null; end if;
   exception
      when Evaluation_Error => Raised := True;
   end;
   Check ("10.1 Literal div zero raises exception", Raised);
   Free_Tree (Node);

   -- 10.2
   Env (Char_To_Var ('X')) := 10;
   Env (Char_To_Var ('Y')) := 0;
   Node := Create_Binary (Op_Div, Create_Variable (Char_To_Var ('X')), Create_Variable (Char_To_Var ('Y')));
   Raised := False;
   begin
      if Evaluate (Node, Env) = 0 then null; end if;
   exception
      when Evaluation_Error => Raised := True;
   end;
   Check ("10.2 Var div zero raises exception", Raised);
   Free_Tree (Node);

   -- 10.3
   Node := Create_Binary (Op_Div, Create_Literal (10), Create_Binary (Op_Sub, Create_Literal (5), Create_Literal (5)));
   Raised := False;
   begin
      if Evaluate (Node, Env) = 0 then null; end if;
   exception
      when Evaluation_Error => Raised := True;
   end;
   Check ("10.3 Expr div zero raises exception", Raised);
   Free_Tree (Node);

   -- TEST 11 - Character Variable Helpers
   Put_Line ("TEST 11 - Character Variable Helpers");
   Check ("11.1 'A' maps to 1", Char_To_Var ('A') = 1);
   Check ("11.2 'z' maps to 26", Char_To_Var ('z') = 26);
   Check ("11.3 13 maps to 'M'", Var_To_Char (13) = 'M');

   -- TEST 12 - Deep Tree Structure
   Put_Line ("TEST 12 - Deep Tree Structure");
   Env := [others => 0];
   Env (Char_To_Var ('A')) := 2;
   Node := Create_Variable (Char_To_Var ('A'));
   for I in 1 .. 10 loop
      pragma Unreferenced (I);
      Node := Create_Binary (Op_Add, Create_Variable (Char_To_Var ('A')), Node);
   end loop;
   Check ("12.1 Deep depth is 11", Tree_Depth (Node) = 11);
   Check ("12.2 Deep eval is 22", Evaluate (Node, Env) = 22);
   Check ("12.3 Deep count is 21", Node_Count (Node) = 21);
   Free_Tree (Node);
   Check ("12.4 Freed deep tree is null", Node = null);

   -- TEST 13 - Environment Mutability
   Put_Line ("TEST 13 - Environment Mutability");
   Node := Create_Binary (Op_Add, Create_Variable (Char_To_Var ('X')), Create_Variable (Char_To_Var ('Y')));
   
   Env := [others => 0];
   Env (Char_To_Var ('X')) := 10;
   Env (Char_To_Var ('Y')) := 20;
   Check ("13.1 Env 1 evaluates to 30", Evaluate (Node, Env) = 30);
   
   Env (Char_To_Var ('X')) := -5;
   Env (Char_To_Var ('Y')) := 5;
   Check ("13.2 Env 2 evaluates to 0", Evaluate (Node, Env) = 0);
   
   Env (Char_To_Var ('X')) := 100;
   Env (Char_To_Var ('Y')) := 200;
   Check ("13.3 Env 3 evaluates to 300", Evaluate (Node, Env) = 300);
   Free_Tree (Node);

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
