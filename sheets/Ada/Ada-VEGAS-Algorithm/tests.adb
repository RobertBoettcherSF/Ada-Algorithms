--  tests.adb
--  Verification & Validation Test Suite for the VEGAS Algorithm
--  Executes 13+ terminal tests ensuring edge cases, errors, and functional inputs pass.

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Exceptions; use Ada.Exceptions;
with Vegas_Algorithm; use Vegas_Algorithm;

procedure Tests is

   -- Helper: Assertion check
   procedure Assert (Condition : Boolean; Message : String) is
   begin
      if Condition then
         Put_Line ("      PASS");
      else
         Put_Line ("      FAIL: " & Message);
         raise Program_Error with Message;
      end if;
   end Assert;

   -- Helper: Margin of Error Check
   function Is_Close (Val, Target, Tolerance : Float) return Boolean is
   begin
      return abs (Val - Target) <= Tolerance;
   end Is_Close;

   -- Test Functions
   function Func_One (X : Vector) return Float is (1.0);
   function Func_Linear (X : Vector) return Float is (X(1));
   function Func_3D (X : Vector) return Float is (X(1) + X(2) + X(3));
   function Func_Negative (X : Vector) return Float is (-2.0);
   
   Res, Var : Float;
   Bounds_1D : constant Domain_Array(1..1) := (1 => (0.0, 1.0));
   Bounds_2D : constant Domain_Array(1..2) := (1 => (0.0, 2.0), 2 => (0.0, 2.0));
   Bounds_3D : constant Domain_Array(1..3) := (1 => (0.0, 1.0), 2 => (0.0, 1.0), 3 => (0.0, 1.0));
   Bounds_Bad : constant Domain_Array(1..1) := (1 => (2.0, 0.0));
   Bounds_Empty : Domain_Array(1..0);

begin
   Put_Line ("Initiating VEGAS Test Suite...");

   -- TEST 1
   Put_Line ("TEST 1 - 1D Constant Integral");
   Put_Line ("  1.1 Assert integrate f(x)=1 over [0,1] is approx 1.0");
   Integrate (Func_One'Unrestricted_Access, Bounds_1D, 5, 1000, Res, Var);
   Assert (Is_Close (Res, 1.0, 0.05), "Result deviation too high. Got " & Float'Image(Res));

   -- TEST 2
   Put_Line ("TEST 2 - 1D Linear Integral");
   Put_Line ("  2.1 Assert integrate f(x)=x over [0,1] is approx 0.5");
   Integrate (Func_Linear'Unrestricted_Access, Bounds_1D, 5, 1000, Res, Var);
   Assert (Is_Close (Res, 0.5, 0.05), "Result deviation too high. Got " & Float'Image(Res));

   -- TEST 3
   Put_Line ("TEST 3 - 2D Constant Integral");
   Put_Line ("  3.1 Assert integrate f(x,y)=1 over [0,2]x[0,2] is approx 4.0");
   Integrate (Func_One'Unrestricted_Access, Bounds_2D, 5, 2000, Res, Var);
   Assert (Is_Close (Res, 4.0, 0.1), "Result deviation too high");

   -- TEST 4
   Put_Line ("TEST 4 - 3D Polynomial Integral");
   Put_Line ("  4.1 Assert integrate f(x,y,z)=x+y+z over [0,1]^3 is approx 1.5");
   Integrate (Func_3D'Unrestricted_Access, Bounds_3D, 5, 2000, Res, Var);
   Assert (Is_Close (Res, 1.5, 0.1), "Result deviation too high");

   -- TEST 5
   Put_Line ("TEST 5 - Constraint: Null Integrand");
   Put_Line ("  5.1 Assert null pointer integrand raises Invalid_Input_Error");
   begin
      Integrate (null, Bounds_1D, 1, 10, Res, Var);
      Assert (False, "Expected Invalid_Input_Error");
   exception
      when Invalid_Input_Error => Put_Line ("      PASS");
   end;

   -- TEST 6
   Put_Line ("TEST 6 - Constraint: Reversed/Invalid Domain Bounds");
   Put_Line ("  6.1 Assert Upper < Lower raises Invalid_Input_Error");
   begin
      Integrate (Func_One'Unrestricted_Access, Bounds_Bad, 1, 10, Res, Var);
      Assert (False, "Expected Invalid_Input_Error");
   exception
      when Invalid_Input_Error => Put_Line ("      PASS");
   end;

   -- TEST 7
   Put_Line ("TEST 7 - Constraint: Empty Domain (0 Dimensions)");
   Put_Line ("  7.1 Assert 0D array raises Invalid_Input_Error");
   begin
      Integrate (Func_One'Unrestricted_Access, Bounds_Empty, 1, 10, Res, Var);
      Assert (False, "Expected Invalid_Input_Error");
   exception
      when Invalid_Input_Error => Put_Line ("      PASS");
   end;

   -- TEST 8
   Put_Line ("TEST 8 - Constraint: Zero Iterations");
   Put_Line ("  8.1 Assert 0 iterations raises Constraint_Error (Positive constraint)");
   begin
      -- Must bypass compile-time checks with local vars
      declare Iter : Integer := 0; begin
         Integrate (Func_One'Unrestricted_Access, Bounds_1D, Iter, 100, Res, Var);
         Assert (False, "Expected Constraint_Error");
      end;
   exception
      when Constraint_Error => Put_Line ("      PASS");
   end;

   -- TEST 9
   Put_Line ("TEST 9 - Constraint: Zero Evaluations");
   Put_Line ("  9.1 Assert 0 evals raises Constraint_Error (Positive constraint)");
   begin
      declare Evals : Integer := 0; begin
         Integrate (Func_One'Unrestricted_Access, Bounds_1D, 5, Evals, Res, Var);
         Assert (False, "Expected Constraint_Error");
      end;
   exception
      when Constraint_Error => Put_Line ("      PASS");
   end;

   -- TEST 10
   Put_Line ("TEST 10 - Negative Results Validation");
   Put_Line ("  10.1 Assert function with strictly negative values evaluates accurately");
   Integrate (Func_Negative'Unrestricted_Access, Bounds_1D, 3, 1000, Res, Var);
   Assert (Is_Close (Res, -2.0, 0.05), "Negative weight mapping failed");

   -- TEST 11
   Put_Line ("TEST 11 - Static Grid vs Dynamic Grid execution");
   Put_Line ("  11.1 Assert VEGAS can run strictly Non-Adaptive (Static MC)");
   Integrate (Func_Linear'Unrestricted_Access, Bounds_1D, 5, 500, Res, Var, Adaptive => False);
   Assert (Is_Close (Res, 0.5, 0.1), "Non-Adaptive execution failed");

   -- TEST 12
   Put_Line ("TEST 12 - Un-Smoothed Grid variant execution");
   Put_Line ("  12.1 Assert Grid adaption functions safely without smoothing");
   Integrate (Func_Linear'Unrestricted_Access, Bounds_1D, 5, 500, Res, Var, Adaptive => True, Smooth_Grid => False);
   Assert (Is_Close (Res, 0.5, 0.1), "Unsmoothed execution failed");

   -- TEST 13
   Put_Line ("TEST 13 - Large Scale Narrow Bounds");
   Put_Line ("  13.1 Assert probability mappings scale properly on microscopic bounds [0.0, 1.0e-5]");
   declare
      Narrow : constant Domain_Array(1..1) := (1 => (0.0, 0.00001));
   begin
      Integrate (Func_One'Unrestricted_Access, Narrow, 3, 1000, Res, Var);
      Assert (Is_Close (Res, 0.00001, 0.000001), "Micro-bounds volume failed");
   end;

   Put_Line ("=============================================");
   Put_Line ("All tests passed! VEGAS algorithm validated.");

end Tests;
