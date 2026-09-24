-- tests.adb
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Ada.Exceptions; use Ada.Exceptions;
with Risch_Algorithm; use Risch_Algorithm;

procedure Tests is
   X : constant Character := 'x';
   Y : constant Character := 'y';
   
   -- Helper variables
   Expr1, Expr2, Result : Expression;
begin
   Put_Line("Executing Test Suite based on Pessimistic Code Assumption...");
   Put_Line("PASS criteria = Assumption of failure is disproved (code functions correctly).");
   Put_Line("");

   -- TEST 1 - Constant Integration
   Put_Line("TEST 1 - Constant Integration");
   Put_Line("  1.1 Assume Integrate(5, 'x') fails to generate 5*x");
   Expr1 := Create_Val(5.0);
   Result := Integrate(Expr1, X);
   Assert(Result.Kind = Mul and then Result.Left.Value = 5.0 and then Result.Right.Name = 'x', "Constant Integration failed");
   Put_Line("      PASS - Assumption Disproved");

   -- TEST 2 - Variable Integration
   Put_Line("TEST 2 - Variable Integration");
   Put_Line("  2.1 Assume Integrate('x', 'x') fails to generate x^2 / 2");
   Expr1 := Create_Var(X);
   Result := Integrate(Expr1, X);
   Assert(Result.Kind = Div and then Result.Left.Kind = Pow, "Variable integration structure incorrect");
   Put_Line("      PASS - Assumption Disproved");

   -- TEST 3 - Sum Integration Branching
   Put_Line("TEST 3 - Symbolic Summation");
   Put_Line("  3.1 Assume Integrate(x + 5) fails to distribute");
   Expr1 := Create_Var(X) + Create_Val(5.0);
   Result := Integrate(Expr1, X);
   Assert(Result.Kind = Add, "Summation distribution failed");
   Put_Line("      PASS - Assumption Disproved");

   -- TEST 4 - Differentiation of Constants
   Put_Line("TEST 4 - Symbolic Differentiation (Constants)");
   Put_Line("  4.1 Assume Derive(5) /= 0");
   Expr1 := Create_Val(5.0);
   Result := Derive(Expr1, X);
   Assert(Result.Value = 0.0, "Derivative of constant is not zero");
   Put_Line("      PASS - Assumption Disproved");

   -- TEST 5 - Differentiation of Variables
   Put_Line("TEST 5 - Symbolic Differentiation (Variables)");
   Put_Line("  5.1 Assume Derive(x, x) /= 1");
   Expr1 := Create_Var(X);
   Result := Derive(Expr1, X);
   Assert(Result.Value = 1.0, "Derivative of variable is not 1");
   Put_Line("      PASS - Assumption Disproved");

   -- TEST 6 - Differentiation (Orthogonal Variables)
   Put_Line("TEST 6 - Independent Variable Differentiation");
   Put_Line("  6.1 Assume Derive(y, x) /= 0");
   Expr1 := Create_Var(Y);
   Result := Derive(Expr1, X);
   Assert(Result.Value = 0.0, "Derivative of orthogonal variable is not 0");
   Put_Line("      PASS - Assumption Disproved");

   -- TEST 7 - Exponential Chain Rule
   Put_Line("TEST 7 - Exponential Derivation");
   Put_Line("  7.1 Assume Derive(e^x) drops the chain rule");
   Expr1 := Create_Exp(Create_Var(X));
   Result := Derive(Expr1, X);
   Assert(Result.Kind = Mul and then Result.Left.Kind = Exp_Func, "Exp derivative failed");
   Put_Line("      PASS - Assumption Disproved");

   -- TEST 8 - Non-Elementary Integration (Gaussian)
   Put_Line("TEST 8 - Liouville's Theorem (Non-Elementary Proof)");
   Put_Line("  8.1 Assume Integrate(e^(x^2)) attempts infinite loop/bad integration");
   begin
      -- e^(x**2)
      Expr1 := Create_Exp(Create_Var(X) ** Create_Val(2.0));
      Result := Integrate(Expr1, X);
      Assert(False, "Should have raised Non_Elementary_Integral");
   exception
      when Non_Elementary_Integral =>
         Put_Line("      PASS - Assumption Disproved (Raised Non_Elementary_Integral correctly)");
   end;

   -- TEST 9 - Structural Null Handling
   Put_Line("TEST 9 - Robustness (Null Inputs)");
   Put_Line("  9.1 Assume Integrate(null) causes Segmentation Fault");
   begin
      Result := Integrate(null, X);
      Assert(False, "Should have raised Invalid_Expression");
   exception
      when Invalid_Expression =>
         Put_Line("      PASS - Assumption Disproved (Raised explicitly)");
   end;

   -- TEST 10 - Tree Simplification (Addition)
   Put_Line("TEST 10 - Algebraic Simplification (Folding)");
   Put_Line("  10.1 Assume Simplify(2.0 + 3.0) remains an Add node");
   Expr1 := Create_Val(2.0) + Create_Val(3.0);
   Result := Simplify(Expr1);
   Assert(Result.Kind = Val and then Result.Value = 5.0, "Simplification of addition failed");
   Put_Line("      PASS - Assumption Disproved");

   -- TEST 11 - Tree Simplification (Identity)
   Put_Line("TEST 11 - Algebraic Simplification (Identity)");
   Put_Line("  11.1 Assume Simplify(1.0 * x) fails to reduce to x");
   Expr1 := Create_Val(1.0) * Create_Var(X);
   Result := Simplify(Expr1);
   Assert(Result.Kind = Var and then Result.Name = X, "Multiplicative identity reduction failed");
   Put_Line("      PASS - Assumption Disproved");

   -- TEST 12 - Hermite Reduction Branch
   Put_Line("TEST 12 - Hermite Reduction Dispatching");
   Put_Line("  12.1 Assume division node fails to trigger Hermite Reduction logic");
   Expr1 := Create_Val(1.0) / (Create_Var(X) ** Create_Val(2.0));
   Result := Integrate(Expr1, X);
   -- Based on our mock, Hermite reduction of 1/x^2 should return -1/x (structurally)
   Assert(Result.Kind = Div, "Hermite branch not taken/failed");
   Put_Line("      PASS - Assumption Disproved");

   -- TEST 13 - Equality Checking
   Put_Line("TEST 13 - Tree Equality Deep Comparison");
   Put_Line("  13.1 Assume identical trees are evaluated as False");
   Expr1 := (Create_Var(X) ** Create_Val(2.0)) + Create_Exp(Create_Var(Y));
   Expr2 := (Create_Var(X) ** Create_Val(2.0)) + Create_Exp(Create_Var(Y));
   Assert(Is_Equal(Expr1, Expr2), "Deep tree equality failed");
   Put_Line("      PASS - Assumption Disproved");
   
   Put_Line("");
   Put_Line("ALL TESTS COMPLETED SUCCESSFULLY.");
end Tests;
