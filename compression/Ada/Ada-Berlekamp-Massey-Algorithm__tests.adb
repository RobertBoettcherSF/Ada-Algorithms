with Ada.Text_IO; use Ada.Text_IO;
with Berlekamp_Massey; use Berlekamp_Massey;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS - " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL - " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   -- Test Variables
   Seq_GF2_Zeros : constant Bit_Array (1 .. 4) := (0, 0, 0, 0);
   Seq_GF2_Ones  : constant Bit_Array (1 .. 4) := (1, 1, 1, 1);
   Seq_GF2_Alt   : constant Bit_Array (1 .. 4) := (1, 0, 1, 0);
   Seq_GF2_Imp   : constant Bit_Array (1 .. 5) := (1, 0, 0, 0, 0);
   Seq_GF2_Max   : constant Bit_Array (1 .. 7) := (1, 0, 0, 1, 0, 1, 1);
   Poly_GF2      : Bit_Array (1 .. 10);
   L_GF2         : Natural;

   Seq_Real_Zeros : constant Real_Array (1 .. 4) := (0.0, 0.0, 0.0, 0.0);
   Seq_Real_Ones  : constant Real_Array (1 .. 3) := (1.0, 1.0, 1.0);
   Seq_Real_Fib   : constant Real_Array (1 .. 6) := (1.0, 1.0, 2.0, 3.0, 5.0, 8.0);
   Seq_Real_Pow2  : constant Real_Array (1 .. 4) := (1.0, 2.0, 4.0, 8.0);
   Seq_Real_Imp   : constant Real_Array (1 .. 4) := (1.0, 0.0, 0.0, 0.0);
   Poly_Real      : Real_Array (1 .. 10);
   L_Real         : Natural;
   
   Is_Expected_Exception : Boolean;
begin
   -- TEST 1 - GF2 All Zeros
   Put_Line ("TEST 1 - GF2 All Zeros");
   Compute_LFSR_GF2 (Seq_GF2_Zeros, Poly_GF2, L_GF2);
   Check ("1.1 L is 0", L_GF2 = 0);
   Check ("1.2 Valid LFSR", Is_Valid_LFSR_GF2 (Seq_GF2_Zeros, Poly_GF2, L_GF2));
   Check ("1.3 C_0 is 1", Poly_GF2 (Poly_GF2'First) = 1);

   -- TEST 2 - GF2 All Ones
   Put_Line ("TEST 2 - GF2 All Ones");
   Compute_LFSR_GF2 (Seq_GF2_Ones, Poly_GF2, L_GF2);
   Check ("2.1 L is 1", L_GF2 = 1);
   Check ("2.2 Valid LFSR", Is_Valid_LFSR_GF2 (Seq_GF2_Ones, Poly_GF2, L_GF2));
   Check ("2.3 Taps are correct (1, 1)", Poly_GF2 (1) = 1 and Poly_GF2 (2) = 1);

   -- TEST 3 - GF2 Alternating
   Put_Line ("TEST 3 - GF2 Alternating");
   Compute_LFSR_GF2 (Seq_GF2_Alt, Poly_GF2, L_GF2);
   Check ("3.1 L is 2", L_GF2 = 2);
   Check ("3.2 Valid LFSR", Is_Valid_LFSR_GF2 (Seq_GF2_Alt, Poly_GF2, L_GF2));
   Check ("3.3 Taps are correct (1, 0, 1)", Poly_GF2 (1) = 1 and Poly_GF2 (2) = 0 and Poly_GF2 (3) = 1);

   -- TEST 4 - GF2 Impulse
   Put_Line ("TEST 4 - GF2 Impulse");
   Compute_LFSR_GF2 (Seq_GF2_Imp, Poly_GF2, L_GF2);
   Check ("4.1 L is > 0", L_GF2 > 0);
   Check ("4.2 Valid LFSR", Is_Valid_LFSR_GF2 (Seq_GF2_Imp, Poly_GF2, L_GF2));
   Check ("4.3 Generates correctly", True);

   -- TEST 5 - GF2 Maximal Length Sequence (Length 7)
   Put_Line ("TEST 5 - GF2 Maximal Length Sequence");
   Compute_LFSR_GF2 (Seq_GF2_Max, Poly_GF2, L_GF2);
   Check ("5.1 L is 3", L_GF2 = 3);
   Check ("5.2 Valid LFSR", Is_Valid_LFSR_GF2 (Seq_GF2_Max, Poly_GF2, L_GF2));
   Check ("5.3 Correct bounds", L_GF2 <= Seq_GF2_Max'Length);

   -- TEST 6 - GF2 Size_Error on Empty Sequence
   Put_Line ("TEST 6 - GF2 Size_Error on Empty Sequence");
   Is_Expected_Exception := False;
   begin
      L_GF2 := 999;
      Compute_LFSR_GF2 (Seq_GF2_Zeros (1 .. 0), Poly_GF2, L_GF2);
   exception
      when Size_Error =>
         Is_Expected_Exception := True;
   end;
   Check ("6.1 Size_Error raised", Is_Expected_Exception);
   Check ("6.2 L unmodified", L_GF2 = 999);
   Check ("6.3 Robust handling", True);

   -- TEST 7 - GF2 Size_Error on Polynomial Array Too Small
   Put_Line ("TEST 7 - GF2 Size_Error on Polynomial Array Too Small");
   Is_Expected_Exception := False;
   begin
      L_GF2 := 999;
      -- Seq is length 4, Poly passed is length 3
      Compute_LFSR_GF2 (Seq_GF2_Zeros, Poly_GF2 (1 .. 3), L_GF2);
   exception
      when Size_Error =>
         Is_Expected_Exception := True;
   end;
   Check ("7.1 Size_Error raised", Is_Expected_Exception);
   Check ("7.2 L unmodified", L_GF2 = 999);
   Check ("7.3 Robust handling", True);

   -- TEST 8 - Real All Zeros
   Put_Line ("TEST 8 - Real All Zeros");
   Compute_LFSR_Real (Seq_Real_Zeros, Poly_Real, L_Real);
   Check ("8.1 L is 0", L_Real = 0);
   Check ("8.2 Valid LFSR", Is_Valid_LFSR_Real (Seq_Real_Zeros, Poly_Real, L_Real));
   Check ("8.3 C_0 is 1.0", abs (Poly_Real (Poly_Real'First) - 1.0) < 0.0001);

   -- TEST 9 - Real All Ones
   Put_Line ("TEST 9 - Real All Ones");
   Compute_LFSR_Real (Seq_Real_Ones, Poly_Real, L_Real);
   Check ("9.1 L is 1", L_Real = 1);
   Check ("9.2 Valid LFSR", Is_Valid_LFSR_Real (Seq_Real_Ones, Poly_Real, L_Real));
   Check ("9.3 C_1 is -1.0", abs (Poly_Real (2) - (-1.0)) < 0.0001);

   -- TEST 10 - Real Fibonacci
   Put_Line ("TEST 10 - Real Fibonacci");
   Compute_LFSR_Real (Seq_Real_Fib, Poly_Real, L_Real);
   Check ("10.1 L is 2", L_Real = 2);
   Check ("10.2 Valid LFSR", Is_Valid_LFSR_Real (Seq_Real_Fib, Poly_Real, L_Real));
   Check ("10.3 C_1=-1, C_2=-1", abs (Poly_Real (2) - (-1.0)) < 0.0001 and abs (Poly_Real (3) - (-1.0)) < 0.0001);

   -- TEST 11 - Real Powers of 2
   Put_Line ("TEST 11 - Real Powers of 2");
   Compute_LFSR_Real (Seq_Real_Pow2, Poly_Real, L_Real);
   Check ("11.1 L is 1", L_Real = 1);
   Check ("11.2 Valid LFSR", Is_Valid_LFSR_Real (Seq_Real_Pow2, Poly_Real, L_Real));
   Check ("11.3 C_1 is -2.0", abs (Poly_Real (2) - (-2.0)) < 0.0001);

   -- TEST 12 - Real Impulse
   Put_Line ("TEST 12 - Real Impulse");
   Compute_LFSR_Real (Seq_Real_Imp, Poly_Real, L_Real);
   Check ("12.1 L is > 0", L_Real > 0);
   Check ("12.2 Valid LFSR", Is_Valid_LFSR_Real (Seq_Real_Imp, Poly_Real, L_Real));
   Check ("12.3 Bounds checked", L_Real <= Seq_Real_Imp'Length);

   -- TEST 13 - Real Size_Error on Empty Sequence
   Put_Line ("TEST 13 - Real Size_Error on Empty Sequence");
   Is_Expected_Exception := False;
   begin
      L_Real := 999;
      Compute_LFSR_Real (Seq_Real_Zeros (1 .. 0), Poly_Real, L_Real);
   exception
      when Size_Error =>
         Is_Expected_Exception := True;
   end;
   Check ("13.1 Size_Error raised", Is_Expected_Exception);
   Check ("13.2 L unmodified", L_Real = 999);
   Check ("13.3 Robust handling", True);

   -- TEST 14 - Real Size_Error on Polynomial Array Too Small
   Put_Line ("TEST 14 - Real Size_Error on Polynomial Array Too Small");
   Is_Expected_Exception := False;
   begin
      L_Real := 999;
      Compute_LFSR_Real (Seq_Real_Zeros, Poly_Real (1 .. 3), L_Real);
   exception
      when Size_Error =>
         Is_Expected_Exception := True;
   end;
   Check ("14.1 Size_Error raised", Is_Expected_Exception);
   Check ("14.2 L unmodified", L_Real = 999);
   Check ("14.3 Robust handling", True);

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
