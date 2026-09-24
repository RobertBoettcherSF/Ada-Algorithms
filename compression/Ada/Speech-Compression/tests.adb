-- tests.adb
-- Validation and Verification test suite

with Ada.Text_IO; use Ada.Text_IO;
with Speech_Encoding; use Speech_Encoding;
with Ada.Exceptions;

procedure Tests is
   Total_Passed : Integer := 0;
   Total_Tests  : Integer := 0;

   -- Custom assert procedure to allow continued execution on failure
   procedure Check (Condition : Boolean; Description : String) is
   begin
      Total_Tests := Total_Tests + 1;
      Put ("    " & Description & " ... ");
      if Condition then
         Put_Line ("PASS");
         Total_Passed := Total_Passed + 1;
      else
         Put_Line ("FAIL (Assumption remains true: Code is broken)");
      end if;
   end Check;

   -- Helper for floating point almost-equal comparisons
   function Almost_Equal (A, B : Audio_Sample; Tolerance : Audio_Sample := 0.001) return Boolean is
   begin
      return abs (A - B) <= Tolerance;
   end Almost_Equal;

begin
   Put_Line ("=============================================");
   Put_Line ("  V&V TEST SUITE: SPEECH ENCODING            ");
   Put_Line ("  Goal: Disprove assumption that code fails  ");
   Put_Line ("=============================================");

   -- TEST 1 - Mu-Law Boundaries and Zero Crossing
   Put_Line ("TEST 1 - Mu-Law Edge & Zero Handling");
   Check (Mu_Law_Encode(0.0) = 0.0, "1.1 Zero encodes to strictly Zero");
   Check (Mu_Law_Encode(1.0) = 1.0, "1.2 Max positive encodes to 1.0");
   Check (Mu_Law_Encode(-1.0) = -1.0, "1.3 Max negative encodes to -1.0");

   -- TEST 2 - Mu-Law Reversibility (Lossy but mathematically symmetric)
   Put_Line ("TEST 2 - Mu-Law Mathematical Reversibility");
   Check (Almost_Equal(Mu_Law_Decode(Mu_Law_Encode(0.5)), 0.5), "2.1 Reversibility at positive 0.5");
   Check (Almost_Equal(Mu_Law_Decode(Mu_Law_Encode(-0.25)), -0.25), "2.2 Reversibility at negative 0.25");

   -- TEST 3 - A-Law Boundaries and Zero Crossing
   Put_Line ("TEST 3 - A-Law Edge & Zero Handling");
   Check (A_Law_Encode(0.0) = 0.0, "3.1 Zero encodes to strictly Zero");
   Check (A_Law_Encode(1.0) = 1.0, "3.2 Max positive encodes to 1.0");
   Check (A_Law_Encode(-1.0) = -1.0, "3.3 Max negative encodes to -1.0");

   -- TEST 4 - A-Law Linear and Logarithmic Regions
   Put_Line ("TEST 4 - A-Law Regional Routing & Reversibility");
   -- Small value (Linear region)
   Check (Almost_Equal(A_Law_Decode(A_Law_Encode(0.005)), 0.005), "4.1 Linear region reversibility");
   -- Large value (Log region)
   Check (Almost_Equal(A_Law_Decode(A_Law_Encode(0.8)), 0.8), "4.2 Logarithmic region reversibility");

   -- TEST 5 - Error Handling (Robustness)
   Put_Line ("TEST 5 - Input Validation Constraints");
   begin
      declare
         Dummy : Audio_Sample := Mu_Law_Encode(1.5);
      begin
         Check (False, "5.1 Out of bounds must raise Invalid_Sample_Error");
      end;
   exception
      when Invalid_Sample_Error => Check (True, "5.1 Expected exception raised on out-of-bounds");
   end;

   -- TEST 6 - DPCM Differential Encoding
   Put_Line ("TEST 6 - DPCM Encoding Logic");
   declare
      In_Buf  : constant Audio_Buffer (1 .. 4) := (0.1, 0.2, 0.2, -0.1);
      Out_Buf : Audio_Buffer (1 .. 4);
   begin
      DPCM_Encode(In_Buf, Out_Buf);
      Check (Almost_Equal(Out_Buf(1), 0.1), "6.1 First value equals difference from zero");
      Check (Almost_Equal(Out_Buf(2), 0.1), "6.2 Second value correctly captures slope");
      Check (Almost_Equal(Out_Buf(3), 0.0), "6.3 Flat signal results in zero differential");
      Check (Almost_Equal(Out_Buf(4), -0.3), "6.4 Downward slope correctly evaluated");
   end;

   -- TEST 7 - DPCM Decoding & Error Handling
   Put_Line ("TEST 7 - DPCM Decoding and Bounds");
   declare
      In_Buf  : constant Audio_Buffer (1 .. 3) := (0.5, -0.1, -0.1);
      Out_Buf : Audio_Buffer (1 .. 3);
      Empty_I : constant Audio_Buffer (1 .. 0) := (others => 0.0);
      Empty_O : Audio_Buffer (1 .. 0);
   begin
      DPCM_Decode(In_Buf, Out_Buf);
      Check (Almost_Equal(Out_Buf(1), 0.5), "7.1 First value recovers correctly");
      Check (Almost_Equal(Out_Buf(3), 0.3), "7.2 Sequential integration recovers original signal");

      begin
         DPCM_Encode(Empty_I, Empty_O);
         Check (False, "7.3 Empty buffer should raise Empty_Buffer_Error");
      exception
         when Empty_Buffer_Error => Check (True, "7.3 Expected exception raised on empty encode");
      end;
   end;

   Put_Line ("=============================================");
   Put_Line ("SUMMARY: " & Integer'Image(Total_Passed) & " / " & Integer'Image(Total_Tests) & " Tests Passed");
   if Total_Passed = Total_Tests then
      Put_Line ("CONCLUSION: Assumption successfully disproved. The code works.");
   else
      Put_Line ("CONCLUSION: The codebase contains faults.");
   end if;

end Tests;
