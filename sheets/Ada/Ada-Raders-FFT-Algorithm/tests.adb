with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Ada.Numerics;
with Raders_FFT; use Raders_FFT;

procedure Tests is
   use Raders_FFT.Complex_Types;

   Pi : constant Real := Real (Ada.Numerics.Pi);

   procedure Assert_Close (A, B : Complex; Msg : String) is
   begin
      Assert (abs (Re (A) - Re (B)) < 1.0e-5 and then abs (Im (A) - Im (B)) < 1.0e-5, Msg);
   end Assert_Close;

   -- V&V Ground Truth DFT Implementation
   procedure Naive_DFT (Input : in Complex_Array; Output : out Complex_Array) is
      N : constant Natural := Input'Length;
      Sum, W : Complex;
      Angle : Real;
   begin
      for K in 0 .. N - 1 loop
         Sum := (0.0, 0.0);
         for J in 0 .. N - 1 loop
            Angle := -2.0 * Pi * Real (K * J) / Real (N);
            W := Compose_From_Polar (1.0, Angle);
            Sum := Sum + Input(Input'First + J) * W;
         end loop;
         Output(Output'First + K) := Sum;
      end loop;
   end Naive_DFT;

begin
   Put_Line ("Starting Test Suite...");
   Put_Line ("");

   -- TEST 1 - Math: Valid Prime Recognition
   begin
      Put_Line ("TEST 1 - Prime Functionality (Normal)");
      Put_Line ("  1.1 Assert 7 is identified as prime");
      Assert (Is_Prime (7), "7 is prime");
      Put_Line ("    PASS");
   exception when E : Assertion_Error => Put_Line ("    FAIL"); end;

   -- TEST 2 - Math: Invalid Prime Rejection
   begin
      Put_Line ("TEST 2 - Prime Functionality (Edge)");
      Put_Line ("  2.1 Assert 8 is identified as non-prime");
      Assert (not Is_Prime (8), "8 is not prime");
      Put_Line ("  2.2 Assert 1 is identified as non-prime");
      Assert (not Is_Prime (1), "1 is not prime");
      Put_Line ("    PASS");
   exception when E : Assertion_Error => Put_Line ("    FAIL"); end;

   -- TEST 3 - Math: Primitive Root Calculation
   begin
      Put_Line ("TEST 3 - Primitive Root Extraction");
      Put_Line ("  3.1 Assert primitive root for 5 is correctly mapped");
      declare
         R : Natural := Primitive_Root (5);
      begin
         Assert (R = 2 or R = 3, "Primitive root of 5 is 2 or 3");
      end;
      Put_Line ("    PASS");
   exception when E : Assertion_Error => Put_Line ("    FAIL"); end;

   -- TEST 4 - Math: Modular Exponentiation
   begin
      Put_Line ("TEST 4 - Modular Exponentiation Check");
      Put_Line ("  4.1 Assert 3^4 mod 5 = 1");
      Assert (Mod_Exp (3, 4, 5) = 1, "Exponentiation failure");
      Put_Line ("    PASS");
   exception when E : Assertion_Error => Put_Line ("    FAIL"); end;

   -- TEST 5 - Math: Next Power of 2 padding function
   begin
      Put_Line ("TEST 5 - Next Power Of 2 Evaluator");
      Put_Line ("  5.1 Assert 5 scales to 8");
      Assert (Next_Power_Of_2 (5) = 8, "Power of 2 calc failure");
      Put_Line ("    PASS");
   exception when E : Assertion_Error => Put_Line ("    FAIL"); end;

   -- TEST 6 - Error Handling: Non-Prime Array Constraints
   begin
      Put_Line ("TEST 6 - Non-Prime Array Rejection");
      Put_Line ("  6.1 Assert size 4 raises Non_Prime_Length_Error");
      declare
         In_Arr : Complex_Array (1 .. 4) := (others => (0.0, 0.0));
         Out_Arr : Complex_Array (1 .. 4);
      begin
         Rader_DFT_Direct (In_Arr, Out_Arr);
         Assert (False, "Exception not raised");
      exception
         when Non_Prime_Length_Error => Put_Line ("    PASS");
      end;
   end;

   -- TEST 7 - Error Handling: Output Bounds Rejection
   begin
      Put_Line ("TEST 7 - Uneven Bound Array Protection");
      Put_Line ("  7.1 Assert bounds mismatch raises Invalid_Input_Error");
      declare
         In_Arr : Complex_Array (1 .. 3) := (others => (0.0, 0.0));
         Out_Arr : Complex_Array (1 .. 5);
      begin
         Rader_DFT_Fast (In_Arr, Out_Arr);
         Assert (False, "Exception not raised");
      exception
         when Invalid_Input_Error => Put_Line ("    PASS");
      end;
   end;

   -- TEST 8 - Domain: DC Input via Direct
   begin
      Put_Line ("TEST 8 - Direct Rader with DC Signals");
      Put_Line ("  8.1 Assert output bins isolate DC effectively");
      declare
         In_Arr : Complex_Array (0 .. 4) := (others => (1.0, 0.0));
         Out_Arr : Complex_Array (0 .. 4);
      begin
         Rader_DFT_Direct (In_Arr, Out_Arr);
         Assert_Close (Out_Arr(0), (5.0, 0.0), "DC zero mismatch");
         Assert_Close (Out_Arr(1), (0.0, 0.0), "DC noise leakage");
      end;
      Put_Line ("    PASS");
   exception when E : Assertion_Error => Put_Line ("    FAIL"); end;

   -- TEST 9 - Domain: DC Input via Fast
   begin
      Put_Line ("TEST 9 - Fast Rader with DC Signals");
      Put_Line ("  9.1 Assert output bins isolate DC effectively");
      declare
         In_Arr : Complex_Array (0 .. 4) := (others => (1.0, 0.0));
         Out_Arr : Complex_Array (0 .. 4);
      begin
         Rader_DFT_Fast (In_Arr, Out_Arr);
         Assert_Close (Out_Arr(0), (5.0, 0.0), "DC zero mismatch");
         Assert_Close (Out_Arr(4), (0.0, 0.0), "DC noise leakage");
      end;
      Put_Line ("    PASS");
   exception when E : Assertion_Error => Put_Line ("    FAIL"); end;

   -- TEST 10 - Ground Truth equivalence: Direct
   begin
      Put_Line ("TEST 10 - Ground Truth against Direct Variant");
      Put_Line ("  10.1 Assert N=7 output strictly matches Naive DFT");
      declare
         In_Arr, Out_Radar, Out_Naive : Complex_Array (0 .. 6);
      begin
         for I in 0 .. 6 loop In_Arr(I) := (Real (I), 0.0); end loop;
         Rader_DFT_Direct (In_Arr, Out_Radar);
         Naive_DFT (In_Arr, Out_Naive);
         for I in 0 .. 6 loop
            Assert_Close (Out_Radar(I), Out_Naive(I), "Data mismatch");
         end loop;
      end;
      Put_Line ("    PASS");
   exception when E : Assertion_Error => Put_Line ("    FAIL"); end;

   -- TEST 11 - Ground Truth equivalence: Fast
   begin
      Put_Line ("TEST 11 - Ground Truth against Fast Variant");
      Put_Line ("  11.1 Assert N=7 output strictly matches Naive DFT");
      declare
         In_Arr, Out_Radar, Out_Naive : Complex_Array (0 .. 6);
      begin
         for I in 0 .. 6 loop In_Arr(I) := (Real (I), 0.0); end loop;
         Rader_DFT_Fast (In_Arr, Out_Radar);
         Naive_DFT (In_Arr, Out_Naive);
         for I in 0 .. 6 loop
            Assert_Close (Out_Radar(I), Out_Naive(I), "Data mismatch");
         end loop;
      end;
      Put_Line ("    PASS");
   exception when E : Assertion_Error => Put_Line ("    FAIL"); end;

   -- TEST 12 - Additivity (Linear System Principle)
   begin
      Put_Line ("TEST 12 - System Linearity V&V");
      Put_Line ("  12.1 Assert DFT(A+B) = DFT(A) + DFT(B)");
      declare
         A : Complex_Array (0 .. 2) := ((1.0, 0.0), (2.0, 0.0), (3.0, 0.0));
         B : Complex_Array (0 .. 2) := ((0.0, 1.0), (0.0, 2.0), (0.0, 3.0));
         A_Plus_B : Complex_Array (0 .. 2);
         F_A, F_B, F_Sum : Complex_Array (0 .. 2);
      begin
         for I in 0 .. 2 loop A_Plus_B(I) := A(I) + B(I); end loop;
         Rader_DFT_Fast (A, F_A);
         Rader_DFT_Fast (B, F_B);
         Rader_DFT_Fast (A_Plus_B, F_Sum);
         for I in 0 .. 2 loop
            Assert_Close (F_Sum(I), F_A(I) + F_B(I), "Linearity fail");
         end loop;
      end;
      Put_Line ("    PASS");
   exception when E : Assertion_Error => Put_Line ("    FAIL"); end;

   -- TEST 13 - Domain Equivalence Fast vs Direct
   begin
      Put_Line ("TEST 13 - Variant Independence validation");
      Put_Line ("  13.1 Assert N=11 results match across models");
      declare
         In_Arr : Complex_Array (0 .. 10);
         Out_Dir, Out_Fst : Complex_Array (0 .. 10);
      begin
         for I in 0 .. 10 loop In_Arr(I) := (Real (I), 0.5); end loop;
         Rader_DFT_Direct (In_Arr, Out_Dir);
         Rader_DFT_Fast (In_Arr, Out_Fst);
         for I in 0 .. 10 loop
            Assert_Close (Out_Dir(I), Out_Fst(I), "Variants drifted");
         end loop;
      end;
      Put_Line ("    PASS");
   exception when E : Assertion_Error => Put_Line ("    FAIL"); end;

   -- TEST 14 - Edge Case (Prime 2 Constraint)
   begin
      Put_Line ("TEST 14 - Edge Condition Validation");
      Put_Line ("  14.1 Assert Prime 2 successfully resolves");
      declare
         In_Arr : Complex_Array (0 .. 1) := ((1.0, 0.0), (2.0, 0.0));
         Out_Arr : Complex_Array (0 .. 1);
      begin
         Rader_DFT_Direct (In_Arr, Out_Arr);
         Assert_Close (Out_Arr(0), (3.0, 0.0), "Bin 0 failed");
         Assert_Close (Out_Arr(1), (-1.0, 0.0), "Bin 1 failed");
      end;
      Put_Line ("    PASS");
   exception when E : Assertion_Error => Put_Line ("    FAIL"); end;

end Tests;
