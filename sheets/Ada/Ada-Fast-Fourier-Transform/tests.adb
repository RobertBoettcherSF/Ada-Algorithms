-- tests.adb
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Numerics.Complex_Types; use Ada.Numerics.Complex_Types;
with FFT; use FFT;

procedure Tests is
   Tolerance : constant Float := 1.0e-4;

   procedure Assert (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Put_Line ("      FAIL: " & Message);
         raise Program_Error with Message;
      else
         Put_Line ("      PASS: " & Message);
      end if;
   end Assert;

   function Approx_Eq (A, B : Complex) return Boolean is
   begin
      return abs (A.Re - B.Re) < Tolerance and abs (A.Im - B.Im) < Tolerance;
   end Approx_Eq;

   function Approx_Eq_Arr (A, B : Complex_Array) return Boolean is
   begin
      if A'Length /= B'Length then return False; end if;
      for I in 0 .. A'Length - 1 loop
         if not Approx_Eq (A (A'First + I), B (B'First + I)) then return False; end if;
      end loop;
      return True;
   end Approx_Eq_Arr;

   -- Shared test data
   Zero_C : constant Complex := (0.0, 0.0);
   Empty_Arr   : Complex_Array (1 .. 0);
   Single_Arr  : constant Complex_Array (0 .. 0) := (0 => (5.0, 0.0));
   Invalid_Arr : constant Complex_Array (0 .. 2) := (others => Zero_C);
   
   Impulse : constant Complex_Array (0 .. 3) := ((1.0, 0.0), Zero_C, Zero_C, Zero_C);
   DC      : constant Complex_Array (0 .. 3) := ((1.0, 0.0), (1.0, 0.0), (1.0, 0.0), (1.0, 0.0));
   Nyquist : constant Complex_Array (0 .. 3) := ((1.0, 0.0), (-1.0, 0.0), (1.0, 0.0), (-1.0, 0.0));
   Sine    : constant Complex_Array (0 .. 3) := (Zero_C, (1.0, 0.0), Zero_C, (-1.0, 0.0));
   
   Output : Complex_Array (0 .. 3);
   N_256  : Complex_Array (0 .. 255);
begin
   Put_Line ("--- V&V Test Suite: Fast Fourier Transform ---");

   Put_Line ("TEST 1 - Edge Case: Empty Array");
   Assert (FFT_Recursive_DIT (Empty_Arr)'Length = 0, "Empty array returns empty");

   Put_Line ("TEST 2 - Edge Case: Single Element");
   Assert (Approx_Eq (FFT_Recursive_DIT (Single_Arr)(0), (5.0, 0.0)), "Single element DC bypasses butterfly");

   Put_Line ("TEST 3 - Constraint Validation: Non-Power of 2");
   begin
      declare
         Res : Complex_Array := FFT_Recursive_DIT (Invalid_Arr);
         pragma Unreferenced (Res);
      begin
         Assert (False, "Should have raised FFT_Error");
      end;
   exception
      when FFT_Error => Assert (True, "Raised FFT_Error appropriately");
   end;

   Put_Line ("TEST 4 - Functional Correctness: Impulse Signal");
   Output := FFT_Recursive_DIT (Impulse);
   Assert (Approx_Eq_Arr (Output, DC), "FFT of delta impulse is uniform DC (all 1s)");

   Put_Line ("TEST 5 - Functional Correctness: DC Signal");
   Output := FFT_Recursive_DIT (DC);
   Assert (Approx_Eq (Output (0), (4.0, 0.0)) and Approx_Eq (Output (1), Zero_C), "FFT of DC peaks at bin 0");

   Put_Line ("TEST 6 - Functional Correctness: Nyquist Frequency");
   Output := FFT_Recursive_DIT (Nyquist);
   Assert (Approx_Eq (Output (2), (4.0, 0.0)) and Approx_Eq (Output (0), Zero_C), "Nyquist alternates peak at N/2 bin");

   Put_Line ("TEST 7 - Functional Correctness: Sine Wave Spectrum");
   Output := FFT_Recursive_DIT (Sine);
   Assert (Approx_Eq (Output (1), (0.0, -2.0)) and Approx_Eq (Output (3), (0.0, 2.0)), "Sine forms conjugate complex pair");

   Put_Line ("TEST 8 - Variant Consistency: DIT vs DIF");
   Assert (Approx_Eq_Arr (FFT_Recursive_DIT (Sine), FFT_Recursive_DIF (Sine)), "DIT outputs perfectly match DIF");

   Put_Line ("TEST 9 - Variant Consistency: DIT vs Iterative");
   Assert (Approx_Eq_Arr (FFT_Recursive_DIT (Nyquist), FFT_Iterative (Nyquist)), "Recursive perfectly matches Iterative");

   Put_Line ("TEST 10 - Inverse Transform Identity (IFFT(FFT(x)) = x)");
   Assert (Approx_Eq_Arr (IFFT (FFT_Recursive_DIT (Nyquist)), Nyquist), "Roundtrip transform recovers input exactly");

   Put_Line ("TEST 11 - Linearity Property (FFT(A) + FFT(B) = FFT(A+B))");
   declare
      Summed_In : Complex_Array (0 .. 3);
      Sum_FFT_1, Sum_FFT_2 : Complex_Array (0 .. 3);
   begin
      for I in 0 .. 3 loop Summed_In (I) := Impulse (I) + Sine (I); end loop;
      Sum_FFT_1 := FFT_Recursive_DIT (Summed_In);
      Output    := FFT_Recursive_DIT (Sine);
      for I in 0 .. 3 loop Sum_FFT_2 (I) := DC (I) + Output (I); end loop;
      Assert (Approx_Eq_Arr (Sum_FFT_1, Sum_FFT_2), "Superposition applies perfectly in frequency domain");
   end;

   Put_Line ("TEST 12 - Parseval's Theorem (Energy Conservation)");
   declare
      E_Time : Float := 0.0;
      E_Freq : Float := 0.0;
   begin
      for I in 0 .. 3 loop
         E_Time := E_Time + (Nyquist (I).Re ** 2 + Nyquist (I).Im ** 2);
         E_Freq := E_Freq + (FFT_Recursive_DIT(Nyquist)(I).Re ** 2 + FFT_Recursive_DIT(Nyquist)(I).Im ** 2);
      end loop;
      Assert (abs (E_Time - (E_Freq / 4.0)) < Tolerance, "Time energy equals Frequency energy scaled by 1/N");
   end;

   Put_Line ("TEST 13 - Helper Function Correctness");
   Assert (Next_Power_Of_2 (3) = 4 and Is_Power_Of_2 (16), "Power of 2 helpers mathematically sound");

   Put_Line ("TEST 14 - Scalability & Roundtrip with N=256");
   for I in N_256'Range loop
      N_256 (I) := (Re => Float (I), Im => 0.0);
   end loop;
   Assert (Approx_Eq_Arr (IFFT (FFT_Recursive_DIT (N_256)), N_256), "Algorithm scales to N=256 maintaining float precision");

   Put_Line ("--- All 14 V&V tests successfully passed. ---");
end Tests;
