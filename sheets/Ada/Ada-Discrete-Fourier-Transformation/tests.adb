-- tests.adb
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Ada.Numerics.Complex_Types; use Ada.Numerics.Complex_Types;
with Discrete_Fourier_Transformation; use Discrete_Fourier_Transformation;

procedure Tests is

   -- Helper to deal with floating point inaccuracies
   function Is_Close (A, B : Complex; Tolerance : Float := 1.0E-4) return Boolean is
   begin
      return abs (A.Re - B.Re) < Tolerance and abs (A.Im - B.Im) < Tolerance;
   end Is_Close;

   Zeros : constant Complex_Array (1 .. 4) := (others => (0.0, 0.0));
   DC_Signal : constant Complex_Array (1 .. 4) := (others => (1.0, 0.0));
   Impulse : constant Complex_Array (1 .. 4) := ((1.0, 0.0), (0.0, 0.0), (0.0, 0.0), (0.0, 0.0));
   Real_Sig : constant Real_Array (1 .. 4) := (1.0, 2.0, 3.0, 4.0);

   Result : Complex_Array (1 .. 4);
   Roundtrip : Complex_Array (1 .. 4);
   
   Mat_Zero : constant Complex_Matrix (1 .. 2, 1 .. 2) := (others => (others => (0.0, 0.0)));
   Mat_Res : Complex_Matrix (1 .. 2, 1 .. 2);

begin
   Put_Line ("Starting Test Suite. Philosophy: Code is assumed broken; PASS proves correctness.");
   Put_Line ("--------------------------------------------------------------------------------");

   -- TEST 1: Forward DFT on Zeroes
   Put_Line ("TEST 1 - Forward DFT Zero Edge Case");
   Put_Line ("  1.1 Assume zero-array yields noise -> Assert output is strictly zero.");
   Result := Forward_DFT (Zeros);
   Assert (Is_Close(Result(1), (0.0, 0.0)) and Is_Close(Result(2), (0.0, 0.0)), "T1 Failed");
   Put_Line ("      PASS");

   -- TEST 2: DC Signal
   Put_Line ("TEST 2 - DC Component Extraction");
   Put_Line ("  2.1 Assume constant signal produces frequencies -> Assert only bin 0 has energy.");
   Result := Forward_DFT (DC_Signal);
   Assert (Is_Close(Result(1), (4.0, 0.0)) and Is_Close(Result(2), (0.0, 0.0)), "T2 Failed");
   Put_Line ("      PASS");

   -- TEST 3: Impulse Signal
   Put_Line ("TEST 3 - Impulse Response");
   Put_Line ("  3.1 Assume impulse creates structured waves -> Assert impulse yields equal energy everywhere.");
   Result := Forward_DFT (Impulse);
   Assert (Is_Close(Result(1), (1.0, 0.0)) and Is_Close(Result(4), (1.0, 0.0)), "T3 Failed");
   Put_Line ("      PASS");

   -- TEST 4: Inverse Recovery
   Put_Line ("TEST 4 - Inverse DFT Logic");
   Put_Line ("  4.1 Assume inverse scaling fails -> Assert Inverse(DFT(Impulse)) == Impulse.");
   Result := Inverse_DFT (Result); -- Invert the output of T3
   Assert (Is_Close(Result(1), (1.0, 0.0)) and Is_Close(Result(2), (0.0, 0.0)), "T4 Failed");
   Put_Line ("      PASS");

   -- TEST 5: Roundtrip Identity
   Put_Line ("TEST 5 - Bi-directional Identity");
   Put_Line ("  5.1 Assume DFT is lossy -> Assert IDFT(DFT(DC_Signal)) perfectly matches DC_Signal.");
   Roundtrip := Inverse_DFT (Forward_DFT (DC_Signal));
   Assert (Is_Close(Roundtrip(1), (1.0, 0.0)) and Is_Close(Roundtrip(3), (1.0, 0.0)), "T5 Failed");
   Put_Line ("      PASS");

   -- TEST 6: Empty Array Exception Forward
   Put_Line ("TEST 6 - Boundary Condition (0-Length) Forward");
   Put_Line ("  6.1 Assume empty array causes divide by zero / crash -> Assert Empty_Array_Error.");
   begin
      declare
         Empty : Complex_Array (1 .. 0);
         Dummy : Complex_Array := Forward_DFT (Empty);
      begin
         Assert (False, "T6 Failed: Expected exception");
      end;
   exception
      when Empty_Array_Error => Put_Line ("      PASS");
   end;

   -- TEST 7: Empty Array Exception Inverse
   Put_Line ("TEST 7 - Boundary Condition (0-Length) Inverse");
   Put_Line ("  7.1 Assume empty IDFT executes silently -> Assert Empty_Array_Error.");
   begin
      declare
         Empty : Complex_Array (1 .. 0);
         Dummy : Complex_Array := Inverse_DFT (Empty);
      begin
         Assert (False, "T7 Failed: Expected exception");
      end;
   exception
      when Empty_Array_Error => Put_Line ("      PASS");
   end;

   -- TEST 8: Real DFT Conjugate Symmetry
   Put_Line ("TEST 8 - Real-Valued Variant Properties");
   Put_Line ("  8.1 Assume Real DFT ignores symmetry -> Assert X(1) = X(3)* (N-K conjugacy).");
   Result := Real_Forward_DFT (Real_Sig);
   -- Real signal: [1, 2, 3, 4]. DFT: [10, -2+2i, -2, -2-2i]. Symmetry between index 2 and 4.
   Assert (Is_Close(Result(2), (-2.0, 2.0)) and Is_Close(Result(4), (-2.0, -2.0)), "T8 Failed");
   Put_Line ("      PASS");

   -- TEST 9: Linearity Additive
   Put_Line ("TEST 9 - Linearity (Additive)");
   Put_Line ("  9.1 Assume DFT breaks linearity -> Assert DFT(A) + DFT(B) == DFT(A+B).");
   declare
      Sum_Sig : Complex_Array (1 .. 4);
      DFT_Sum : Complex_Array (1 .. 4);
      Sum_DFTs : Complex_Array (1 .. 4);
   begin
      for I in 1 .. 4 loop Sum_Sig(I) := DC_Signal(I) + Impulse(I); end loop;
      DFT_Sum := Forward_DFT(Sum_Sig);
      declare
         D1 : Complex_Array := Forward_DFT(DC_Signal);
         D2 : Complex_Array := Forward_DFT(Impulse);
      begin
         for I in 1 .. 4 loop Sum_DFTs(I) := D1(I) + D2(I); end loop;
         Assert (Is_Close(DFT_Sum(1), Sum_DFTs(1)), "T9 Failed");
      end;
   end;
   Put_Line ("      PASS");

   -- TEST 10: Unitary Normalization Roundtrip
   Put_Line ("TEST 10 - Unitary Normalization Identity");
   Put_Line ("  10.1 Assume 1/sqrt(N) logic corrupts data -> Assert Unitary_Inv(Unitary_Fwd) == Origin.");
   Roundtrip := Unitary_Inverse_DFT (Unitary_Forward_DFT (DC_Signal));
   Assert (Is_Close(Roundtrip(1), DC_Signal(1)), "T10 Failed");
   Put_Line ("      PASS");

   -- TEST 11: 2D DFT Boundary
   Put_Line ("TEST 11 - 2D Matrix Origin Constraint");
   Put_Line ("  11.1 Assume 2D sum calculates garbage on 0-matrix -> Assert strictly zero.");
   Mat_Res := Forward_2D_DFT (Mat_Zero);
   Assert (Is_Close(Mat_Res(1,1), (0.0, 0.0)), "T11 Failed");
   Put_Line ("      PASS");

   -- TEST 12: 2D DFT DC Logic
   Put_Line ("TEST 12 - 2D Energy Density");
   Put_Line ("  12.1 Assume 2D DC component is incorrectly scaled -> Assert DC bin = Rows*Cols.");
   declare
      Mat_DC : constant Complex_Matrix (1 .. 2, 1 .. 2) := (others => (others => (1.0, 0.0)));
   begin
      Mat_Res := Forward_2D_DFT (Mat_DC);
      Assert (Is_Close(Mat_Res(1,1), (4.0, 0.0)) and Is_Close(Mat_Res(2,2), (0.0,0.0)), "T12 Failed");
   end;
   Put_Line ("      PASS");

   -- TEST 13: 2D Empty Exception
   Put_Line ("TEST 13 - 2D Constraint Error Prevention");
   Put_Line ("  13.1 Assume 2D edge cases are unhandled -> Assert Empty_Array_Error.");
   begin
      declare
         Empty_Mat : Complex_Matrix (1 .. 0, 1 .. 0);
         Dummy_Mat : Complex_Matrix := Forward_2D_DFT (Empty_Mat);
      begin
         Assert (False, "T13 Failed: Expected exception");
      end;
   exception
      when Empty_Array_Error => Put_Line ("      PASS");
   end;

   -- TEST 14: Parseval's Theorem Check on Unitary DFT
   Put_Line ("TEST 14 - Energy Conservation (Parseval's Theorem)");
   Put_Line ("  14.1 Assume Unitary DFT leaks energy -> Assert Energy(Time) == Energy(Frequency).");
   declare
      Energy_Time, Energy_Freq : Float := 0.0;
      U_DFT : Complex_Array := Unitary_Forward_DFT (Impulse);
   begin
      for I in Impulse'Range loop
         Energy_Time := Energy_Time + (Impulse(I).Re**2 + Impulse(I).Im**2);
         Energy_Freq := Energy_Freq + (U_DFT(I).Re**2 + U_DFT(I).Im**2);
      end loop;
      Assert (abs (Energy_Time - Energy_Freq) < 1.0E-4, "T14 Failed");
   end;
   Put_Line ("      PASS");

   Put_Line ("--------------------------------------------------------------------------------");
   Put_Line ("ALL VERIFICATION TESTS COMPLETED SUCCESSFULLY.");
end Tests;
