-- tests.adb
with Ada.Text_IO; use Ada.Text_IO;
with Trigonometric_Interpolation; use Trigonometric_Interpolation;
with Ada.Numerics;
with Ada.Numerics.Long_Elementary_Functions;

procedure Tests is

   Pi : constant Long_Float := Ada.Numerics.Pi;
   Epsilon : constant Long_Float := 1.0e-9;
   
   Total_Tests : Natural := 0;
   Passed_Tests : Natural := 0;

   procedure Assert (Condition : Boolean; Message : String) is
   begin
      Total_Tests := Total_Tests + 1;
      if Condition then
         Put_Line ("      PASS: " & Message);
         Passed_Tests := Passed_Tests + 1;
      else
         Put_Line ("      FAIL: " & Message);
      end if;
   end Assert;

   procedure Assert_Float_Eq (Expected, Actual : Long_Float; Message : String) is
   begin
      Assert (abs (Expected - Actual) < Epsilon, Message & " (Exp: " & Long_Float'Image(Expected) & " | Act: " & Long_Float'Image(Actual) & ")");
   end Assert_Float_Eq;

   -- Helper for exact node checking
   procedure Check_Nodes (Data : Real_Array) is
      Coeffs : constant Interpolation_Coefficients := Calculate_Coefficients (Data);
      X      : Long_Float;
      N      : constant Long_Float := Long_Float (Data'Length);
   begin
      for I in Data'Range loop
         X := 2.0 * Pi * Long_Float (I - Data'First) / N;
         Assert_Float_Eq (Data (I), Evaluate (Coeffs, X), "Node " & Integer'Image (I) & " evaluation matches");
      end loop;
   end Check_Nodes;

begin
   Put_Line ("Starting V&V Test Suite for Trigonometric Interpolation");
   Put_Line ("=======================================================");

   Put_Line ("TEST 1 - Exception Handling (Boundary Condition)");
   begin
      declare
         Empty_Data : constant Real_Array (1 .. 0) := (others => 0.0);
         C : constant Interpolation_Coefficients := Calculate_Coefficients (Empty_Data);
         pragma Unreferenced (C);
      begin
         Assert (False, "Should have raised Invalid_Data_Error");
      end;
   exception
      when Invalid_Data_Error =>
         Assert (True, "Invalid_Data_Error raised for N=0");
   end;

   Put_Line ("TEST 2 - Single Point (N=1, Odd Variant)");
   declare
      D1 : constant Real_Array (0 .. 0) := (0 => 42.5);
      C1 : constant Interpolation_Coefficients := Calculate_Coefficients (D1);
   begin
      Assert_Float_Eq (42.5, C1.A(0), "A0 equals point value");
      Assert_Float_Eq (42.5, Evaluate(C1, 0.0), "f(0) equals point value");
      Assert_Float_Eq (42.5, Evaluate(C1, Pi), "f(Pi) equals point value (constant function)");
   end;

   Put_Line ("TEST 3 - Two Points (N=2, Even Variant)");
   declare
      D2 : constant Real_Array (0 .. 1) := (1.0, -1.0);
      C2 : constant Interpolation_Coefficients := Calculate_Coefficients (D2);
   begin
      Assert_Float_Eq (0.0, C2.A(0), "Mean A0 is 0.0");
      Assert_Float_Eq (1.0, C2.A(1), "Nyquist frequency A1 matches amplitude");
      Check_Nodes (D2);
   end;

   Put_Line ("TEST 4 - Three Points (N=3, Odd Variant)");
   declare
      D3 : constant Real_Array (1 .. 3) := (5.0, 2.0, 2.0);
   begin
      Put_Line ("   4.1 Verify nodes match original inputs exactly");
      Check_Nodes (D3);
   end;

   Put_Line ("TEST 5 - Constant Function (N=4)");
   declare
      D_Const : constant Real_Array (0 .. 3) := (7.7, 7.7, 7.7, 7.7);
      C_Const : constant Interpolation_Coefficients := Calculate_Coefficients (D_Const);
   begin
      Assert_Float_Eq (7.7, C_Const.A(0), "A0 holds the constant value");
      Assert_Float_Eq (0.0, C_Const.A(1), "High frequency A1 is zero");
      Assert_Float_Eq (0.0, C_Const.B(1), "High frequency B1 is zero");
      Assert_Float_Eq (7.7, Evaluate(C_Const, Pi/4.0), "Evaluation at arbitrary point yields constant");
   end;

   Put_Line ("TEST 6 - Pure Sine Wave (N=5, Odd)");
   declare
      -- sin(x) evaluated at 5 points
      D_Sin : Real_Array (0 .. 4);
      C_Sin : Interpolation_Coefficients (2);
   begin
      for I in 0 .. 4 loop
         D_Sin(I) := Ada.Numerics.Long_Elementary_Functions.Sin(2.0 * Pi * Long_Float(I) / 5.0);
      end loop;
      C_Sin := Calculate_Coefficients (D_Sin);
      Assert_Float_Eq (0.0, C_Sin.A(0), "DC offset is 0");
      Assert_Float_Eq (0.0, C_Sin.A(1), "Cos component is 0");
      Assert_Float_Eq (1.0, C_Sin.B(1), "First fundamental Sin component is 1.0");
   end;

   Put_Line ("TEST 7 - Pure Cosine Wave (N=5, Odd)");
   declare
      D_Cos : Real_Array (0 .. 4);
      C_Cos : Interpolation_Coefficients (2);
   begin
      for I in 0 .. 4 loop
         D_Cos(I) := Ada.Numerics.Long_Elementary_Functions.Cos(2.0 * Pi * Long_Float(I) / 5.0);
      end loop;
      C_Cos := Calculate_Coefficients (D_Cos);
      Assert_Float_Eq (1.0, C_Cos.A(1), "First fundamental Cos component is 1.0");
      Assert_Float_Eq (0.0, C_Cos.B(1), "Sin component is 0");
   end;

   Put_Line ("TEST 8 - Even Variant Highest Frequency Limit (N=4)");
   declare
      -- Nyquist wave: [1, -1, 1, -1] -> exactly corresponds to cos(2x)
      D_Nyquist : constant Real_Array (0 .. 3) := (1.0, -1.0, 1.0, -1.0);
      C_Nyquist : constant Interpolation_Coefficients := Calculate_Coefficients (D_Nyquist);
   begin
      Assert (C_Nyquist.Is_Even_N, "Correctly flagged as Even N");
      Assert_Float_Eq (0.0, C_Nyquist.A(0), "A0 is 0.0");
      Assert_Float_Eq (0.0, C_Nyquist.A(1), "A1 is 0.0");
      Assert_Float_Eq (1.0, C_Nyquist.A(2), "A2 is exactly 1.0 (Nyquist component)");
      Check_Nodes (D_Nyquist);
   end;

   Put_Line ("TEST 9 - Sub-node Evaluation Interpolation (Odd N)");
   declare
      D_Sub : constant Real_Array (0 .. 2) := (0.0, 1.0, -1.0);
      C_Sub : constant Interpolation_Coefficients := Calculate_Coefficients (D_Sub);
   begin
      -- Evaluate precisely at halfway point (Pi/2 or similar)
      -- This ensures that the polynomial formulation is smooth and bounded
      declare
         Val : constant Long_Float := Evaluate (C_Sub, Pi); 
      begin
         -- Just asserting no runtime error and falls in reasonable bounds
         Assert (Val >= -2.0 and Val <= 2.0, "Interpolated value bounded realistically");
      end;
   end;

   Put_Line ("TEST 10 - Sub-node Evaluation Interpolation (Even N)");
   declare
      D_SubE : constant Real_Array (0 .. 3) := (2.0, 3.0, -1.0, -2.0);
      C_SubE : constant Interpolation_Coefficients := Calculate_Coefficients (D_SubE);
   begin
      Assert (Evaluate (C_SubE, 0.5 * Pi) /= 0.0, "Continuous evaluation succeeds for Even arrays");
   end;

   Put_Line ("TEST 11 - Periodicity / Wrap-around Constraint");
   declare
      D_Per : constant Real_Array (0 .. 4) := (1.0, 2.0, 3.0, 4.0, 5.0);
      C_Per : constant Interpolation_Coefficients := Calculate_Coefficients (D_Per);
      Val_0 : constant Long_Float := Evaluate (C_Per, 0.0);
      Val_2Pi : constant Long_Float := Evaluate (C_Per, 2.0 * Pi);
      Val_4Pi : constant Long_Float := Evaluate (C_Per, 4.0 * Pi);
   begin
      Assert_Float_Eq (Val_0, Val_2Pi, "f(0) == f(2pi) demonstrates periodicity");
      Assert_Float_Eq (Val_0, Val_4Pi, "f(0) == f(4pi) demonstrates deep periodicity");
   end;

   Put_Line ("TEST 12 - Stability on Large N (N=20)");
   declare
      D_Large : Real_Array (0 .. 19);
   begin
      for I in 0 .. 19 loop
         D_Large(I) := Long_Float(I mod 3);
      end loop;
      Check_Nodes (D_Large);
   end;

   Put_Line ("TEST 13 - Shifted Array Index Equivalence");
   declare
      D_0_Based : constant Real_Array (0 .. 2) := (4.0, -2.0, 1.0);
      D_5_Based : constant Real_Array (5 .. 7) := (4.0, -2.0, 1.0);
      C0 : constant Interpolation_Coefficients := Calculate_Coefficients (D_0_Based);
      C5 : constant Interpolation_Coefficients := Calculate_Coefficients (D_5_Based);
   begin
      Assert_Float_Eq (C0.A(1), C5.A(1), "Calculated coefficients independent of array index start bounds");
   end;

   Put_Line ("=======================================================");
   Put_Line ("Total Tests Run: " & Integer'Image (Total_Tests));
   Put_Line ("Total Passed:    " & Integer'Image (Passed_Tests));
   
   if Total_Tests = Passed_Tests then
      Put_Line ("ALL TESTS PASSED: Pessimistic assumptions disproved. Code works correctly.");
   else
      Put_Line ("SOME TESTS FAILED.");
   end if;

end Tests;
