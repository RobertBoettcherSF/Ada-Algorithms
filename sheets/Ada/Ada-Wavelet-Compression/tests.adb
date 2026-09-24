-- tests.adb
-- Verification and Validation suite for Wavelet Compression

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Wavelet_Compression; use Wavelet_Compression;

procedure Tests is
   Epsilon : constant Float := 0.0001;

   function Are_Close (A, B : Signal_1D) return Boolean is
   begin
      if A'Length /= B'Length then return False; end if;
      for I in A'Range loop
         if abs (A(I) - B(I)) > Epsilon then return False; end if;
      end loop;
      return True;
   end Are_Close;
   
   function Are_Close_2D (A, B : Signal_2D) return Boolean is
   begin
      if A'Length(1) /= B'Length(1) or A'Length(2) /= B'Length(2) then return False; end if;
      for I in A'Range(1) loop
         for J in A'Range(2) loop
            if abs (A(I,J) - B(I,J)) > Epsilon then return False; end if;
         end loop;
      end loop;
      return True;
   end Are_Close_2D;

   -- Test Data
   S1       : Signal_1D(1..4) := (1.0, 3.0, 5.0, 7.0);
   S1_Trans : Signal_1D(1..4);
   S1_Rec   : Signal_1D(1..4);

   S2       : Signal_1D_Int(1..4) := (2, 4, 6, 8);
   S2_Trans : Signal_1D_Int(1..4);
   S2_Rec   : Signal_1D_Int(1..4);
   
   M1       : Signal_2D(1..2, 1..2) := ((1.0, 2.0), (3.0, 4.0));
   M1_Trans : Signal_2D(1..2, 1..2);
   M1_Rec   : Signal_2D(1..2, 1..2);

begin
   Put_Line("=============================================");
   Put_Line(" Wavelet Compression Verification & Validation");
   Put_Line("=============================================");

   -- TEST 1
   Put_Line("TEST 1 - Lossy 1D Forward Transform");
   Put_Line("  1.1 Assert Float Forward generates expected averages and differences");
   S1_Trans := Forward_Haar_1D(S1);
   Assert(abs (S1_Trans(1) - 2.0) < Epsilon and abs (S1_Trans(3) - (-1.0)) < Epsilon, "1D Forward Failed");
   Put_Line("     PASS");

   -- TEST 2
   Put_Line("TEST 2 - Lossy 1D Inverse Transform (Reconstruction)");
   Put_Line("  2.1 Assert Inverse applied to Forward restores original signal");
   S1_Rec := Inverse_Haar_1D(S1_Trans);
   Assert(Are_Close(S1, S1_Rec), "1D Inverse Failed");
   Put_Line("     PASS");

   -- TEST 3
   Put_Line("TEST 3 - Lossless 1D Forward (Integer Lifting)");
   Put_Line("  3.1 Assert Integer lifting isolates details safely");
   S2_Trans := Forward_Haar_1D_Lossless(S2);
   Assert(S2_Trans(1) = 3 and S2_Trans(3) = -2, "Lossless 1D Forward Failed");
   Put_Line("     PASS");

   -- TEST 4
   Put_Line("TEST 4 - Lossless 1D Inverse (Perfect Reconstruction)");
   Put_Line("  4.1 Assert integer inversion creates zero data loss");
   S2_Rec := Inverse_Haar_1D_Lossless(S2_Trans);
   Assert(S2_Rec = S2, "Lossless 1D Inverse Failed");
   Put_Line("     PASS");

   -- TEST 5
   Put_Line("TEST 5 - Lossy 2D Forward Transform");
   Put_Line("  5.1 Assert 2D float transform processes rows and cols correctly");
   M1_Trans := Forward_Haar_2D(M1);
   Assert(abs (M1_Trans(1,1) - 2.5) < Epsilon, "2D Forward Failed");
   Put_Line("     PASS");

   -- TEST 6
   Put_Line("TEST 6 - Lossy 2D Inverse Transform");
   Put_Line("  6.1 Assert 2D inverse reconstructs original matrix");
   M1_Rec := Inverse_Haar_2D(M1_Trans);
   Assert(Are_Close_2D(M1, M1_Rec), "2D Inverse Failed");
   Put_Line("     PASS");

   -- TEST 7
   Put_Line("TEST 7 - Quantization Compression step");
   Put_Line("  7.1 Assert thresholding suppresses minor wavelets safely");
   declare
      Sig : Signal_1D(1..4) := (10.0, 0.5, -0.2, 5.0);
      Q   : Signal_1D(1..4);
   begin
      Q := Quantize(Sig, 1.0);
      Assert(Q(2) = 0.0 and Q(3) = 0.0 and Q(1) = 10.0, "Quantization Failed");
      Put_Line("     PASS");
   end;

   -- TEST 8
   Put_Line("TEST 8 - Input Boundaries (Odd Dimensions)");
   Put_Line("  8.1 Assert uneven lengths raise Invalid_Dimensions");
   begin
      declare
         Odd_Sig : Signal_1D(1..3) := (1.0, 2.0, 3.0);
         Dummy   : Signal_1D(1..3);
      begin
         Dummy := Forward_Haar_1D(Odd_Sig);
         Assert(False, "Expected Invalid_Dimensions not raised");
      end;
   exception
      when Invalid_Dimensions =>
         Put_Line("     PASS");
   end;

   -- TEST 9
   Put_Line("TEST 9 - Input Boundaries (Size 1)");
   Put_Line("  9.1 Assert size 1 bypasses math and returns self");
   declare
      One : Signal_1D(1..1) := (1 => 42.0);
      Res : Signal_1D(1..1);
   begin
      Res := Forward_Haar_1D(One);
      Assert(Res(1) = 42.0, "Size 1 failed");
      Put_Line("     PASS");
   end;

   -- TEST 10
   Put_Line("TEST 10 - Lossy transform on Constant Signal");
   Put_Line("  10.1 Assert differences (high-pass) become 0.0");
   declare
      Const_Sig : Signal_1D(1..4) := (4.0, 4.0, 4.0, 4.0);
      Res       : Signal_1D(1..4) := Forward_Haar_1D(Const_Sig);
   begin
      Assert(abs (Res(3)) < Epsilon and abs(Res(4)) < Epsilon, "Constant details not zero");
      Put_Line("     PASS");
   end;

   -- TEST 11
   Put_Line("TEST 11 - Lossless transform on Constant Signal");
   Put_Line("  11.1 Assert details are exactly integer 0");
   declare
      Const_Sig : Signal_1D_Int(1..4) := (5, 5, 5, 5);
      Res       : Signal_1D_Int(1..4) := Forward_Haar_1D_Lossless(Const_Sig);
   begin
      Assert(Res(3) = 0 and Res(4) = 0, "Constant details not zero");
      Put_Line("     PASS");
   end;

   -- TEST 12
   Put_Line("TEST 12 - Negative Values Integer Transform");
   Put_Line("  12.1 Assert negative numbers correctly processed by lifting scheme");
   declare
      Neg_Sig : Signal_1D_Int(1..4) := (-2, -4, -6, -8);
      Trans   : Signal_1D_Int(1..4) := Forward_Haar_1D_Lossless(Neg_Sig);
      Rec     : Signal_1D_Int(1..4) := Inverse_Haar_1D_Lossless(Trans);
   begin
      Assert(Rec = Neg_Sig, "Negative integers failed reconstruction");
      Put_Line("     PASS");
   end;

   -- TEST 13
   Put_Line("TEST 13 - Total Quantization");
   Put_Line("  13.1 Assert high threshold drops signal entirely to zeroes");
   declare
      Sig : Signal_1D(1..4) := (1.0, -1.0, 2.0, -2.0);
      Q   : Signal_1D(1..4) := Quantize(Sig, 10.0);
   begin
      Assert(Q(1) = 0.0 and Q(2) = 0.0 and Q(3) = 0.0 and Q(4) = 0.0, "Total quant failed");
      Put_Line("     PASS");
   end;

   Put_Line("=============================================");
   Put_Line(" ALL 13 ASSUMPTIONS DISPROVEN. CODE WORKS.");
   Put_Line("=============================================");
end Tests;
