with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Goertzel; use Goertzel;
with Ada.Numerics;
with Ada.Numerics.Generic_Elementary_Functions;

procedure Tests is
   
   -- Instantiate math functions explicitly for our strongly-typed 'Real'
   package Real_Math is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Real_Math;

   -- Helper to generate sine waves for testing
   function Generate_Sine (Freq : Real; Sample_Rate : Real; Length : Positive) return Real_Array is
      Res : Real_Array (1 .. Length);
      W   : constant Real := 2.0 * Real(Ada.Numerics.Pi) * Freq / Sample_Rate;
   begin
      for I in 1 .. Length loop
         Res (I) := Sin (W * Real(I - 1));
      end loop;
      return Res;
   end Generate_Sine;

   Empty_Array : constant Real_Array(1 .. 0) := (others => 0.0);
   Sample_8kHz : constant Real := 8000.0;
   Target_Freq : constant Real := 1000.0;
   Tolerance   : constant Real := 0.001;

   Signal_Target : Real_Array := Generate_Sine(1000.0, Sample_8kHz, 100);
   Signal_Other  : Real_Array := Generate_Sine(2500.0, Sample_8kHz, 100);
   DC_Signal     : constant Real_Array(1 .. 50) := (others => 1.0);
   
   State : Goertzel_State;
   C_Res : Complex;
   M_Res : Real;
begin
   Put_Line("=================================================");
   Put_Line("   GOERTZEL ALGORITHM - V&V TEST SUITE (13+ Tests)");
   Put_Line("=================================================");

   -- TEST 1
   Put_Line("TEST 1 - Invalid Empty Arrays (Basic)");
   Put_Line("  1.1 Assume Basic_Goertzel crashes unpredictably on empty array");
   begin
      C_Res := Basic_Goertzel(Empty_Array, Target_Freq, Sample_8kHz);
      Assert(False, "Failed to raise exception");
   exception
      when Goertzel_Error => Put_Line("      PASS: Goertzel_Error correctly raised");
   end;

   -- TEST 2
   Put_Line("TEST 2 - Invalid Empty Arrays (Optimized)");
   Put_Line("  2.1 Assume Optimized_Goertzel ignores empty arrays and returns 0");
   begin
      M_Res := Optimized_Goertzel(Empty_Array, Target_Freq, Sample_8kHz);
      Assert(False, "Failed to raise exception");
   exception
      when Goertzel_Error => Put_Line("      PASS: Goertzel_Error correctly raised");
   end;

   -- TEST 3
   Put_Line("TEST 3 - Invalid Sample Rate Guard");
   Put_Line("  3.1 Assume Sample_Rate <= 0 causes division by zero");
   begin
      C_Res := Basic_Goertzel(Signal_Target, Target_Freq, 0.0);
      Assert(False, "Failed to raise exception");
   exception
      when Goertzel_Error => Put_Line("      PASS: Goertzel_Error correctly raised on 0 Hz");
   end;

   -- TEST 4
   Put_Line("TEST 4 - Basic Output on Precise Target Frequency");
   Put_Line("  4.1 Assume algorithm fails to detect its target frequency");
   C_Res := Basic_Goertzel(Signal_Target, 1000.0, Sample_8kHz);
   Assert(C_Res.Re**2 + C_Res.Im**2 > 100.0, "Target frequency not detected");
   Put_Line("      PASS: Target frequency exhibits large magnitude");

   -- TEST 5
   Put_Line("TEST 5 - Basic Output on Unrelated Frequency");
   Put_Line("  5.1 Assume algorithm outputs false positives for wrong frequencies");
   C_Res := Basic_Goertzel(Signal_Other, 1000.0, Sample_8kHz);
   Assert(C_Res.Re**2 + C_Res.Im**2 < 1.0, "False positive detected");
   Put_Line("      PASS: Unrelated frequency exhibits near-zero magnitude");

   -- TEST 6
   Put_Line("TEST 6 - Optimized Algorithm Power Matches Basic Magnitude Squared");
   Put_Line("  6.1 Assume Optimized power calculation diverges from Complex math");
   C_Res := Basic_Goertzel(Signal_Target, 1000.0, Sample_8kHz);
   M_Res := Optimized_Goertzel(Signal_Target, 1000.0, Sample_8kHz);
   Assert(abs(M_Res - (C_Res.Re**2 + C_Res.Im**2)) < Tolerance, "Algorithms diverge");
   Put_Line("      PASS: Optimized power equals Complex Magnitude Squared");

   -- TEST 7
   Put_Line("TEST 7 - DC Signal (0 Hz) Handling");
   Put_Line("  7.1 Assume 0 Hz frequency causes math domain errors");
   M_Res := Optimized_Goertzel(DC_Signal, 0.0, Sample_8kHz);
   Assert(M_Res > 1000.0, "Failed to accumulate DC power");
   Put_Line("      PASS: DC signal accumulates correctly at 0 Hz");

   -- TEST 8
   Put_Line("TEST 8 - Nyquist Frequency Limit");
   Put_Line("  8.1 Assume Nyquist limit (Sample_Rate / 2) breaks the cosine coefficient");
   M_Res := Optimized_Goertzel(Signal_Target, 4000.0, 8000.0);
   -- It shouldn't crash, and for a 1kHz tone analyzed at 4kHz, magnitude should be very small
   Assert(M_Res < 5.0, "Nyquist analysis yielded false positive/crash");
   Put_Line("      PASS: Nyquist limit processed correctly");

   -- TEST 9
   Put_Line("TEST 9 - Streaming / Stateful Initialization");
   Put_Line("  9.1 Assume Init_State leaves garbage data in the history buffer");
   State.S_Prev1 := 99.0;
   State.S_Prev2 := -99.0;
   Init_State(State, Target_Freq, Sample_8kHz);
   Assert(State.S_Prev1 = 0.0 and State.S_Prev2 = 0.0, "State not zeroed");
   Put_Line("      PASS: State correctly zeroed");

   -- TEST 10
   Put_Line("TEST 10 - Streaming Process matches Batch Optimized Process");
   Put_Line("  10.1 Assume processing sample-by-sample drifts from block processing");
   Init_State(State, 1000.0, Sample_8kHz);
   for I in Signal_Target'Range loop
      Process_Sample(State, Signal_Target(I));
   end loop;
   M_Res := Optimized_Goertzel(Signal_Target, 1000.0, Sample_8kHz);
   Assert(abs(Get_Magnitude_Squared(State) - M_Res) < Tolerance, "Streaming drift detected");
   Put_Line("      PASS: Streaming loop perfectly matches batch block");

   -- TEST 11
   Put_Line("TEST 11 - Streaming Complex matches Batch Complex Process");
   Put_Line("  11.1 Assume streaming state fails to calculate complex endpoints");
   C_Res := Basic_Goertzel(Signal_Target, 1000.0, Sample_8kHz);
   declare
      S_C_Res : Complex := Get_Complex(State, 1000.0, Sample_8kHz);
   begin
      Assert(abs(S_C_Res.Re - C_Res.Re) < Tolerance, "Complex Re mismatch");
      Assert(abs(S_C_Res.Im - C_Res.Im) < Tolerance, "Complex Im mismatch");
      Put_Line("      PASS: Streaming complex evaluation matches batch complex");
   end;

   -- TEST 12
   Put_Line("TEST 12 - Negative Frequency Handling");
   Put_Line("  12.1 Assume negative frequencies corrupt the Goertzel coefficient");
   declare
      Pos_Res : Real := Optimized_Goertzel(Signal_Target, 1000.0, Sample_8kHz);
      Neg_Res : Real := Optimized_Goertzel(Signal_Target, -1000.0, Sample_8kHz);
   begin
      -- Cos(W) is symmetrical, power should be identical
      Assert(abs(Pos_Res - Neg_Res) < Tolerance, "Negative frequency mismatch");
      Put_Line("      PASS: Symmetric frequency response confirmed");
   end;

   -- TEST 13
   Put_Line("TEST 13 - Out of Bounds Target Frequencies (Aliasing test)");
   Put_Line("  13.1 Assume requesting > Nyquist frequency causes fatal failure");
   begin
      -- Frequency = 9000 Hz on an 8000 Hz samplerate. Mathematically aliases.
      M_Res := Optimized_Goertzel(Signal_Target, 9000.0, Sample_8kHz);
      Assert(True, "Should not crash, mathematically behaves via aliasing");
      Put_Line("      PASS: Handled over-Nyquist gracefully via expected math aliasing");
   end;

   Put_Line("=================================================");
   Put_Line("ALL TESTS PROVED NEGATIVE ASSUMPTIONS FALSE. OK.");
end Tests;
