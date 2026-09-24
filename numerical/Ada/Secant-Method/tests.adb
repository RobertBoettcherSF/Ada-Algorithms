with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Secant_Method; use Secant_Method;

procedure Tests is

   -- Test Functions
   -- f(x) = x^2 - 4 (Roots at -2 and 2)
   function Func_Quad (X : Real) return Real is
   begin
      return X**2 - 4.0;
   end Func_Quad;

   -- f(x) = 5 (Flat function, no roots)
   function Func_Flat (X : Real) return Real is
      pragma Unreferenced (X); -- Prevents the -gnatwu warning
   begin
      return 5.0;
   end Func_Flat;

   -- f(x) = x^3 - x^2 - 1 (Root approx 1.465)
   function Func_Cubic (X : Real) return Real is
   begin
      return X**3 - X**2 - 1.0;
   end Func_Cubic;

   Res : Root_Result;

begin
   Put_Line ("========================================");
   Put_Line ("Secant Method - V&V Pessimistic Testing ");
   Put_Line ("========================================");

   -- TEST 1: Secant Standard Root Finding
   Put_Line ("TEST 1 - Standard Secant: Normal Convergence");
   Put_Line ("  1.1 Assume code fails to find positive root of x^2-4");
   Res := Standard_Secant (Func_Quad'Access, 0.0, 3.0);
   Assert (abs (Res.Root - 2.0) <= 1.0E-7, "Failed to find root at x=2");
   Put_Line ("      PASS: Assumption disproven. Root found accurately.");

   Put_Line ("  1.2 Assume code returns incorrect status enum");
   Assert (Res.Status = Success, "Returned non-Success status");
   Put_Line ("      PASS: Assumption disproven. Status is Success.");

   Put_Line ("  1.3 Assume iterations logic is broken (Iter = 0)");
   Assert (Res.Iterations > 0, "Iterations not properly tracked");
   Put_Line ("      PASS: Assumption disproven. Iterations tracked.");

   -- TEST 2: Secant Division By Zero Edge Case
   Put_Line ("TEST 2 - Standard Secant: Division By Zero Prevention");
   Put_Line ("  2.1 Assume same initial guesses crash the system");
   Res := Standard_Secant (Func_Quad'Access, 3.0, 3.0);
   Assert (Res.Status = Division_By_Zero, "Did not handle division by zero");
   Put_Line ("      PASS: Assumption disproven. Handled identical guesses.");

   Put_Line ("  2.2 Assume completely flat function crashes system");
   Res := Standard_Secant (Func_Flat'Access, 1.0, 2.0);
   Assert (Res.Status = Division_By_Zero, "Did not handle flat function div-zero");
   Put_Line ("      PASS: Assumption disproven. Handled zero gradient.");

   -- TEST 3: Secant Maximum Iterations
   Put_Line ("TEST 3 - Standard Secant: Bounded Execution");
   Put_Line ("  3.1 Assume algorithm infinite loops on low max_iter");
   Res := Standard_Secant (Func_Quad'Access, 0.0, 3.0, Max_Iter => 1);
   Assert (Res.Status = Max_Iterations_Reached, "Did not abort at max iterations");
   Put_Line ("      PASS: Assumption disproven. Escaped safely.");

   -- TEST 4: Secant Negative Root
   Put_Line ("TEST 4 - Standard Secant: Negative Constraints");
   Put_Line ("  4.1 Assume code fails to locate negative roots (-2)");
   Res := Standard_Secant (Func_Quad'Access, -3.0, -1.0);
   Assert (abs (Res.Root - (-2.0)) <= 1.0E-7, "Failed to find root at x=-2");
   Put_Line ("      PASS: Assumption disproven. Root found.");

   -- TEST 5: False Position Validity
   Put_Line ("TEST 5 - False Position: Normal Convergence");
   Put_Line ("  5.1 Assume False Position fails on x^2 - 4 bracketed at [0,3]");
   Res := False_Position (Func_Quad'Access, 0.0, 3.0);
   Assert (abs (Res.Root - 2.0) <= 1.0E-7, "Failed to find root at x=2");
   Put_Line ("      PASS: Assumption disproven. Root found accurately.");

   Put_Line ("  5.2 Assume False Position returns incorrect status");
   Assert (Res.Status = Success, "Returned non-Success status");
   Put_Line ("      PASS: Assumption disproven. Status is Success.");

   -- TEST 6: False Position Bracket Validation
   Put_Line ("TEST 6 - False Position: Bracket Validation");
   Put_Line ("  6.1 Assume missing bracket silently returns wrong data");
   Res := False_Position (Func_Quad'Access, 4.0, 5.0); -- Both positive
   Assert (Res.Status = Invalid_Bracket, "Did not catch invalid bracket");
   Put_Line ("      PASS: Assumption disproven. Handled invalid bracket.");

   -- TEST 7: Advanced Tolerance Checking
   Put_Line ("TEST 7 - Functional Precision bounds");
   Put_Line ("  7.1 Assume algorithm ignores tight tolerance (1.0E-12)");
   Res := Standard_Secant (Func_Cubic'Access, 1.0, 2.0, Tolerance => 1.0E-12);
   Assert (abs (Func_Cubic(Res.Root)) <= 1.0E-10, "Failed tight tolerance");
   Put_Line ("      PASS: Assumption disproven. Precise root found.");

   -- TEST 8: False Position Max Iterations 
   Put_Line ("TEST 8 - False Position: Bounded Execution");
   Put_Line ("  8.1 Assume False Position infinite loops on bad iteration bounds");
   Res := False_Position (Func_Quad'Access, 0.0, 3.0, Max_Iter => 2);
   Assert (Res.Status = Max_Iterations_Reached, "Did not abort correctly");
   Put_Line ("      PASS: Assumption disproven. Bounded appropriately.");

   -- TEST 9: General Integration
   Put_Line ("TEST 9 - System Integrity");
   Put_Line ("  9.1 Assume function pointer execution degrades over time");
   Res := Standard_Secant (Func_Cubic'Access, 1.0, 2.0);
   Assert (Res.Status = Success, "Failed on Cubic integration");
   Put_Line ("      PASS: Assumption disproven. System robust on multiple runs.");
   
   Put_Line ("========================================");
   Put_Line ("ALL TESTS COMPLETED SUCCESSFULLY.");
end Tests;
