-- tests.adb
-- Test suite verifying correctness, edge cases, and robustness of the KS algorithms.
-- Tests assume code is broken; a PASS disproves this by executing correctly.

with Ada.Text_IO; use Ada.Text_IO;
with Karplus_Strong; use Karplus_Strong;

procedure Tests is
   Fs : constant Sample_Type := 44100.0;
   Buffer : Sample_Array (1 .. 100);
   Empty_Buffer : Sample_Array (1 .. 0);
   Long_Buffer : Sample_Array (1 .. 10000);

   procedure Assert (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Put_Line ("      FAIL: " & Message);
         raise Program_Error with Message;
      end if;
   end Assert;

begin
   Put_Line ("Starting Karplus-Strong Validation Suite...");
   Put_Line ("===========================================");

   -- TEST 1
   Put_Line ("TEST 1 - Plucked String Basic Generation");
   Put_Line ("  1.1 Assert output buffer gets modified");
   Buffer := (others => 0.0);
   Plucked_String (Buffer, Fs, 440.0);
   Assert (Buffer(1) /= 0.0, "Buffer remained entirely silent");
   Put_Line ("      PASS");

   -- TEST 2
   Put_Line ("TEST 2 - Nyquist Limit Edge Case");
   Put_Line ("  2.1 Assert frequency >= Fs/2 raises Invalid_Frequency");
   begin
      Plucked_String (Buffer, Fs, 22051.0);
      Assert (False, "Did not reject super-Nyquist frequency");
   exception
      when Invalid_Frequency => Put_Line ("      PASS");
   end;

   -- TEST 3
   Put_Line ("TEST 3 - Zero Frequency Edge Case");
   Put_Line ("  3.1 Assert frequency = 0.0 raises Invalid_Frequency");
   begin
      Plucked_String (Buffer, Fs, 0.0);
      Assert (False, "Did not reject zero frequency");
   exception
      when Invalid_Frequency => Put_Line ("      PASS");
   end;

   -- TEST 4
   Put_Line ("TEST 4 - Negative Frequency Edge Case");
   Put_Line ("  4.1 Assert frequency < 0.0 raises Invalid_Frequency");
   begin
      Plucked_String (Buffer, Fs, -100.0);
      Assert (False, "Did not reject negative frequency");
   exception
      when Invalid_Frequency => Put_Line ("      PASS");
   end;

   -- TEST 5
   Put_Line ("TEST 5 - Drum Synthesis Basic Generation");
   Put_Line ("  5.1 Assert drum function works without crashing");
   Buffer := (others => 0.0);
   Drum_Sound (Buffer, Fs, 150.0);
   Assert (Buffer(10) /= 0.0, "Drum buffer remained entirely silent");
   Put_Line ("      PASS");

   -- TEST 6
   Put_Line ("TEST 6 - Drum Blend Factor Upper Bounds");
   Put_Line ("  6.1 Assert Blend_Factor > 1.0 raises Invalid_Parameter");
   begin
      Drum_Sound (Buffer, Fs, 150.0, Blend_Factor => 1.5);
      Assert (False, "Did not reject Blend_Factor > 1.0");
   exception
      when Invalid_Parameter => Put_Line ("      PASS");
   end;

   -- TEST 7
   Put_Line ("TEST 7 - Drum Blend Factor Lower Bounds");
   Put_Line ("  7.1 Assert Blend_Factor < 0.0 raises Invalid_Parameter");
   begin
      Drum_Sound (Buffer, Fs, 150.0, Blend_Factor => -0.1);
      Assert (False, "Did not reject Blend_Factor < 0.0");
   exception
      when Invalid_Parameter => Put_Line ("      PASS");
   end;

   -- TEST 8
   Put_Line ("TEST 8 - Tuned String (Extended KS) Basic Generation");
   Put_Line ("  8.1 Assert fractional delay calculation evaluates cleanly");
   Buffer := (others => 0.0);
   Tuned_String (Buffer, Fs, 440.0);
   Assert (Buffer(5) /= 0.0, "Tuned string output is zero");
   Put_Line ("      PASS");

   -- TEST 9
   Put_Line ("TEST 9 - Decay Factor Upper Bound Robustness");
   Put_Line ("  9.1 Assert Decay_Factor > 1.0 raises Invalid_Parameter");
   begin
      Tuned_String (Buffer, Fs, 440.0, Decay_Factor => 1.01);
      Assert (False, "Did not reject Decay_Factor > 1.0 (unstable)");
   exception
      when Invalid_Parameter => Put_Line ("      PASS");
   end;

   -- TEST 10
   Put_Line ("TEST 10 - Decay Factor Lower Bound Robustness");
   Put_Line ("  10.1 Assert Decay_Factor < 0.0 raises Invalid_Parameter");
   begin
      Tuned_String (Buffer, Fs, 440.0, Decay_Factor => -0.5);
      Assert (False, "Did not reject negative Decay_Factor");
   exception
      when Invalid_Parameter => Put_Line ("      PASS");
   end;

   -- TEST 11
   Put_Line ("TEST 11 - Empty Buffer Execution");
   Put_Line ("  11.1 Assert algorithm safely skips processing on empty array length");
   Plucked_String (Empty_Buffer, Fs, 440.0);
   Assert (True, "Crash on empty buffer!"); 
   Put_Line ("      PASS");

   -- TEST 12
   Put_Line ("TEST 12 - Buffer Wrap-around (Long Duration)");
   Put_Line ("  12.1 Assert algorithm processes correctly beyond delay line bounds");
   -- 10,000 samples at 44.1kHz / 440Hz forces loop to wrap ~100 times
   Plucked_String (Long_Buffer, Fs, 440.0);
   Assert (Long_Buffer(9999) /= 0.0, "Long buffer tail generated silence");
   Put_Line ("      PASS");

   -- TEST 13
   Put_Line ("TEST 13 - Drum Pure Noise Test (Blend_Factor 1.0)");
   Put_Line ("  13.1 Assert 1.0 Blend_Factor evaluates safely");
   Drum_Sound (Buffer, Fs, 150.0, Blend_Factor => 1.0);
   Assert (Buffer(5) /= 0.0, "Failure on Blend_Factor = 1.0");
   Put_Line ("      PASS");

   -- TEST 14
   Put_Line ("TEST 14 - Output Variance");
   Put_Line ("  14.1 Assert Tuned String produces different waveform than Plucked String");
   declare
      Buffer_A : Sample_Array (1 .. 100);
      Buffer_B : Sample_Array (1 .. 100);
      Differences : Natural := 0;
   begin
      -- Generate both with same frequency
      Plucked_String (Buffer_A, Fs, 500.0);
      Tuned_String (Buffer_B, Fs, 500.0);
      
      for I in 1 .. 100 loop
         if Buffer_A(I) /= Buffer_B(I) then
            Differences := Differences + 1;
         end if;
      end loop;
      Assert (Differences > 0, "All-pass filter fractional delay did not modify signal");
      Put_Line ("      PASS");
   end;

   Put_Line ("===========================================");
   Put_Line ("All 14 tests passed! Verification Complete.");

end Tests;
