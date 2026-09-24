-- tests.adb
-- Validation & Verification suite. 
-- Philosophy: Assume the code is broken. Tests pass by asserting correct states, disproving the assumption.

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with EZW; use EZW;

procedure Tests is
begin
   Put_Line ("========================================");
   Put_Line ("   EZW Algorithm V&V Test Suite         ");
   Put_Line ("========================================");

   -- TEST 1
   Put_Line ("TEST 1 - Threshold Initialization (Empty)");
   Put_Line ("  1.1 Assert exception raised on empty matrix");
   declare
      Empty_Mat : Wavelet_Matrix (1 .. 0);
      Dummy : Threshold_Value;
   begin
      Dummy := Compute_Initial_Threshold(Empty_Mat);
      Assert (False, "Expected Empty_Matrix_Error not raised");
   exception
      when Empty_Matrix_Error => Put_Line ("      PASS (Assumption disproved)");
   end;

   -- TEST 2
   Put_Line ("TEST 2 - Threshold Initialization (Max Normal)");
   Put_Line ("  2.1 Assert threshold for max 63 is 32");
   declare
      Mat : Wavelet_Matrix := (1 => 10, 2 => -63, 3 => 5);
   begin
      Assert (Compute_Initial_Threshold(Mat) = 32, "Threshold calculation failed");
      Put_Line ("      PASS");
   end;

   -- TEST 3
   Put_Line ("TEST 3 - Threshold Initialization (Power of 2)");
   Put_Line ("  3.1 Assert threshold for max 64 is 64");
   declare
      Mat : Wavelet_Matrix := (1 => 64, 2 => 0);
   begin
      Assert (Compute_Initial_Threshold(Mat) = 64, "Threshold calculation failed on power of 2");
      Put_Line ("      PASS");
   end;

   -- TEST 4
   Put_Line ("TEST 4 - Zerotree Root Detection (True)");
   Put_Line ("  4.1 Assert node and all descendants < Threshold returns True");
   declare
      Mat : Wavelet_Matrix (1 .. 5) := (others => 5);
   begin
      Assert (Is_Zerotree_Root(Mat, 1, 10) = True, "Expected True for ZTR");
      Put_Line ("      PASS");
   end;

   -- TEST 5
   Put_Line ("TEST 5 - Zerotree Root Detection (False - Self)");
   Put_Line ("  5.1 Assert self >= Threshold returns False");
   declare
      Mat : Wavelet_Matrix (1 .. 5) := (1 => 15, others => 5);
   begin
      Assert (Is_Zerotree_Root(Mat, 1, 10) = False, "Expected False for ZTR");
      Put_Line ("      PASS");
   end;

   -- TEST 6
   Put_Line ("TEST 6 - Zerotree Root Detection (False - Child)");
   Put_Line ("  6.1 Assert deep child >= Threshold returns False");
   declare
      Mat : Wavelet_Matrix (1 .. 5) := (1 => 5, 2 => 5, 3 => 15, 4 => 5, 5 => 5);
   begin
      Assert (Is_Zerotree_Root(Mat, 1, 10) = False, "Expected False for ZTR due to child");
      Put_Line ("      PASS");
   end;

   -- TEST 7
   Put_Line ("TEST 7 - Dominant Pass (POS)");
   Put_Line ("  7.1 Assert positive significant coefficient emits POS");
   declare
      Mat : Wavelet_Matrix (1 .. 1) := (1 => 35);
      Sig : Significance_Map (1 .. 1) := (others => False);
      Str : Encoded_Stream (10);
   begin
      Dominant_Pass (Mat, Sig, 32, Str);
      Assert (Str.Symbols(1) = POS, "Expected POS");
      Assert (Sig(1) = True, "Expected Significant flag set");
      Put_Line ("      PASS");
   end;

   -- TEST 8
   Put_Line ("TEST 8 - Dominant Pass (NEG)");
   Put_Line ("  8.1 Assert negative significant coefficient emits NEG");
   declare
      Mat : Wavelet_Matrix (1 .. 1) := (1 => -35);
      Sig : Significance_Map (1 .. 1) := (others => False);
      Str : Encoded_Stream (10);
   begin
      Dominant_Pass (Mat, Sig, 32, Str);
      Assert (Str.Symbols(1) = NEG, "Expected NEG");
      Put_Line ("      PASS");
   end;

   -- TEST 9
   Put_Line ("TEST 9 - Dominant Pass (IZ)");
   Put_Line ("  9.1 Assert node < Threshold but child > Threshold emits IZ");
   declare
      Mat : Wavelet_Matrix (1 .. 5) := (1 => 10, 3 => 40, others => 5);
      Sig : Significance_Map (1 .. 5) := (others => False);
      Str : Encoded_Stream (10);
   begin
      Dominant_Pass (Mat, Sig, 32, Str);
      Assert (Str.Symbols(1) = IZ, "Expected IZ");
      Put_Line ("      PASS");
   end;

   -- TEST 10
   Put_Line ("TEST 10 - Dominant Pass (ZTR)");
   Put_Line ("  10.1 Assert node and children < Threshold emits ZTR");
   declare
      Mat : Wavelet_Matrix (1 .. 5) := (others => 5);
      Sig : Significance_Map (1 .. 5) := (others => False);
      Str : Encoded_Stream (10);
   begin
      Dominant_Pass (Mat, Sig, 32, Str);
      Assert (Str.Symbols(1) = ZTR, "Expected ZTR");
      Put_Line ("      PASS");
   end;

   -- TEST 11
   Put_Line ("TEST 11 - Dominant Pass Ignore Logic");
   Put_Line ("  11.1 Assert already significant node emits nothing");
   declare
      Mat : Wavelet_Matrix (1 .. 1) := (1 => 40);
      Sig : Significance_Map (1 .. 1) := (1 => True);
      Str : Encoded_Stream (10);
   begin
      Dominant_Pass (Mat, Sig, 32, Str);
      Assert (Str.Count = 0, "Expected no symbols emitted");
      Put_Line ("      PASS");
   end;

   -- TEST 12
   Put_Line ("TEST 12 - Subordinate Pass (Bit 1)");
   Put_Line ("  12.1 Assert value 45 at threshold 32 yields SUB_1");
   declare
      Mat : Wavelet_Matrix (1 .. 1) := (1 => 45);
      Sig : Significance_Map (1 .. 1) := (1 => True);
      Str : Encoded_Stream (10);
   begin
      Subordinate_Pass (Mat, Sig, 32, Str);
      Assert (Str.Symbols(1) = SUB_1, "Expected SUB_1 bit");
      Put_Line ("      PASS");
   end;

   -- TEST 13
   Put_Line ("TEST 13 - Subordinate Pass (Bit 0)");
   Put_Line ("  13.1 Assert value 45 at threshold 16 yields SUB_0");
   declare
      Mat : Wavelet_Matrix (1 .. 1) := (1 => 45);
      Sig : Significance_Map (1 .. 1) := (1 => True);
      Str : Encoded_Stream (10);
   begin
      Subordinate_Pass (Mat, Sig, 16, Str);
      Assert (Str.Symbols(1) = SUB_0, "Expected SUB_0 bit");
      Put_Line ("      PASS");
   end;

   -- TEST 14
   Put_Line ("TEST 14 - Stream Overflow Protection");
   Put_Line ("  14.1 Assert writing past Max_Size raises Overflow");
   declare
      Mat : Wavelet_Matrix (1 .. 2) := (1 => 40, 2 => 40);
      Sig : Significance_Map (1 .. 2) := (others => False);
      Str : Encoded_Stream (1); -- Capacity 1, attempting to write 2
   begin
      Dominant_Pass(Mat, Sig, 32, Str);
      Assert (False, "Expected Stream_Overflow_Error");
   exception
      when Stream_Overflow_Error => Put_Line ("      PASS");
   end;
   
   Put_Line ("========================================");
   Put_Line ("ALL TESTS PASSED SUCCESSFULLY");
end Tests;
