with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Ada.Numerics.Complex_Types; use Ada.Numerics.Complex_Types;
with Cooley_Tukey; use Cooley_Tukey;

procedure Tests is
   Tolerance : constant Float := 1.0e-4;

   procedure Assert_Approx_Equal (Val, Expected : Complex; Msg : String) is
   begin
      Assert (abs (Val.Re - Expected.Re) < Tolerance and 
              abs (Val.Im - Expected.Im) < Tolerance, Msg);
   end Assert_Approx_Equal;

   -- Helper arrays
   DC_Signal_4    : Complex_Array (0 .. 3) := ((1.0, 0.0), (1.0, 0.0), (1.0, 0.0), (1.0, 0.0));
   Impulse_4      : Complex_Array (0 .. 3) := ((1.0, 0.0), (0.0, 0.0), (0.0, 0.0), (0.0, 0.0));
   Nyquist_4      : Complex_Array (0 .. 3) := ((1.0, 0.0), (-1.0, 0.0), (1.0, 0.0), (-1.0, 0.0));
   Invalid_Size_3 : Complex_Array (0 .. 2) := ((1.0, 0.0), (2.0, 0.0), (3.0, 0.0));
   Linear_4       : Complex_Array (0 .. 3) := ((1.0, 0.0), (2.0, 0.0), (3.0, 0.0), (4.0, 0.0));
begin
   Put_Line ("Starting V&V Test Suite for Cooley-Tukey FFT");
   Put_Line ("============================================");

   -- TEST 1 - Power of Two Validation
   Put_Line ("TEST 1 - Power of Two Validation");
   Put_Line ("  1.1 Assert Is_Power_Of_Two correctly identifies valid boundaries (2, 4, 8)");
   Assert (Is_Power_Of_Two (2), "Failed on 2");
   Assert (Is_Power_Of_Two (4), "Failed on 4");
   Assert (Is_Power_Of_Two (8), "Failed on 8");
   Put_Line ("      PASS");

   -- TEST 2 - Power of Two Rejection
   Put_Line ("TEST 2 - Power of Two Rejection");
   Put_Line ("  2.1 Assert Is_Power_Of_Two rejects invalid integers (0, 3, 5)");
   Assert (not Is_Power_Of_Two (0), "Failed on 0");
   Assert (not Is_Power_Of_Two (3), "Failed on 3");
   Assert (not Is_Power_Of_Two (5), "Failed on 5");
   Put_Line ("      PASS");

   -- TEST 3 - Bit Reversal Logic
   Put_Line ("TEST 3 - Bit Reversal Logic");
   Put_Line ("  3.1 Assert Bit_Reverse sorts linear array into correct bit-reversed order");
   declare
      B_Array : Complex_Array (0 .. 3) := ((0.0, 0.0), (1.0, 0.0), (2.0, 0.0), (3.0, 0.0));
   begin
      Bit_Reverse (B_Array);
      Assert_Approx_Equal (B_Array (0), (0.0, 0.0), "Index 00 -> 00 failed");
      Assert_Approx_Equal (B_Array (1), (2.0, 0.0), "Index 01 -> 10 failed");
      Assert_Approx_Equal (B_Array (2), (1.0, 0.0), "Index 10 -> 01 failed");
      Assert_Approx_Equal (B_Array (3), (3.0, 0.0), "Index 11 -> 11 failed");
      Put_Line ("      PASS");
   end;

   -- TEST 4 - Iterative FFT DC Signal
   Put_Line ("TEST 4 - Iterative FFT DC Signal");
   Put_Line ("  4.1 Assert Iterative FFT on constant signal produces [N, 0, 0...]");
   declare
      A : Complex_Array := DC_Signal_4;
   begin
      FFT_Iterative (A);
      Assert_Approx_Equal (A (0), (4.0, 0.0), "Bin 0 failed");
      Assert_Approx_Equal (A (1), (0.0, 0.0), "Bin 1 failed");
      Assert_Approx_Equal (A (2), (0.0, 0.0), "Bin 2 failed");
      Assert_Approx_Equal (A (3), (0.0, 0.0), "Bin 3 failed");
      Put_Line ("      PASS");
   end;

   -- TEST 5 - Recursive FFT DC Signal
   Put_Line ("TEST 5 - Recursive FFT DC Signal");
   Put_Line ("  5.1 Assert Recursive FFT on constant signal matches expected bounds");
   declare
      A : Complex_Array := DC_Signal_4;
   begin
      FFT_Recursive (A);
      Assert_Approx_Equal (A (0), (4.0, 0.0), "Bin 0 failed");
      Assert_Approx_Equal (A (3), (0.0, 0.0), "Bin 3 failed");
      Put_Line ("      PASS");
   end;

   -- TEST 6 - Iterative FFT Single Impulse
   Put_Line ("TEST 6 - Iterative FFT Single Impulse");
   Put_Line ("  6.1 Assert Impulse [1,0,0,0] transforms to pure frequencies [1,1,1,1]");
   declare
      A : Complex_Array := Impulse_4;
   begin
      FFT_Iterative (A);
      for I in A'Range loop
         Assert_Approx_Equal (A (I), (1.0, 0.0), "Impulse bin failed");
      end loop;
      Put_Line ("      PASS");
   end;

   -- TEST 7 - Recursive FFT Single Impulse
   Put_Line ("TEST 7 - Recursive FFT Single Impulse");
   Put_Line ("  7.1 Assert Recursive Impulse [1,0,0,0] transforms to [1,1,1,1]");
   declare
      A : Complex_Array := Impulse_4;
   begin
      FFT_Recursive (A);
      for I in A'Range loop
         Assert_Approx_Equal (A (I), (1.0, 0.0), "Recursive Impulse bin failed");
      end loop;
      Put_Line ("      PASS");
   end;

   -- TEST 8 - Iterative FFT Nyquist Frequency
   Put_Line ("TEST 8 - Iterative FFT Nyquist Frequency");
   Put_Line ("  8.1 Assert Nyquist signal [1,-1,1,-1] maps strictly to N/2 bin");
   declare
      A : Complex_Array := Nyquist_4;
   begin
      FFT_Iterative (A);
      Assert_Approx_Equal (A (0), (0.0, 0.0), "DC offset should be 0");
      Assert_Approx_Equal (A (2), (4.0, 0.0), "Nyquist bin should contain all energy");
      Put_Line ("      PASS");
   end;

   -- TEST 9 - Consistency Between Iterative and Recursive Variants
   Put_Line ("TEST 9 - Algorithm Consistency");
   Put_Line ("  9.1 Assert Iterative and Recursive output identical results for complex inputs");
   declare
      A_Iter, A_Rec : Complex_Array := Linear_4;
   begin
      FFT_Iterative (A_Iter);
      FFT_Recursive (A_Rec);
      for I in A_Iter'Range loop
         Assert_Approx_Equal (A_Iter (I), A_Rec (I), "Outputs diverge at index " & Integer'Image (I));
      end loop;
      Put_Line ("      PASS");
   end;

   -- TEST 10 - Iterative Exception Handling
   Put_Line ("TEST 10 - Iterative Exception Handling");
   Put_Line ("  10.1 Assert Iterative FFT rejects non-power-of-2 dimensions");
   begin
      declare
         A : Complex_Array := Invalid_Size_3;
      begin
         FFT_Iterative (A);
         Assert (False, "Expected Invalid_Size_Error not raised");
      end;
   exception
      when Invalid_Size_Error => Put_Line ("      PASS");
   end;

   -- TEST 11 - Recursive Exception Handling
   Put_Line ("TEST 11 - Recursive Exception Handling");
   Put_Line ("  11.1 Assert Recursive FFT rejects non-power-of-2 dimensions");
   begin
      declare
         A : Complex_Array := Invalid_Size_3;
      begin
         FFT_Recursive (A);
         Assert (False, "Expected Invalid_Size_Error not raised");
      end;
   exception
      when Invalid_Size_Error => Put_Line ("      PASS");
   end;

   -- TEST 12 - IFFT Base Functionality
   Put_Line ("TEST 12 - IFFT Base Functionality");
   Put_Line ("  12.1 Assert IFFT reverses the frequency domain back to time domain");
   declare
      A : Complex_Array := Linear_4;
   begin
      FFT_Iterative (A);
      IFFT (A);
      for I in A'Range loop
         Assert_Approx_Equal (A (I), Linear_4 (I), "IFFT did not recreate original array");
      end loop;
      Put_Line ("      PASS");
   end;

   -- TEST 13 - Parseval's Theorem Constraint (Energy Conservation)
   Put_Line ("TEST 13 - Parseval's Theorem");
   Put_Line ("  13.1 Assert Total Energy in Time Domain = Total Energy in Freq Domain / N");
   declare
      A : Complex_Array := Linear_4;
      Time_Energy, Freq_Energy : Float := 0.0;
   begin
      for I in A'Range loop
         Time_Energy := Time_Energy + (A (I).Re ** 2) + (A (I).Im ** 2);
      end loop;
      
      FFT_Iterative (A);
      for I in A'Range loop
         Freq_Energy := Freq_Energy + (A (I).Re ** 2) + (A (I).Im ** 2);
      end loop;
      
      -- Compare scaled energy
      Assert (abs (Time_Energy - (Freq_Energy / Float (A'Length))) < Tolerance, 
             "Energy constraint violated!");
      Put_Line ("      PASS");
   end;

   Put_Line ("============================================");
   Put_Line ("ALL 13 TESTS PASSED. Assumptions of failure proven false.");
end Tests;
