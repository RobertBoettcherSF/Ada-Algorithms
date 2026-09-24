-- tests.adb
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Numerics.Complex_Types; use Ada.Numerics.Complex_Types;
with Ada.Numerics.Complex_Elementary_Functions; use Ada.Numerics.Complex_Elementary_Functions;
with Ada.Numerics;
with Bluestein; use Bluestein;

procedure Tests is
   Tolerance : constant Float := 1.0e-3;
   Pi : constant Float := Ada.Numerics.Pi;

   procedure Assert (Condition : Boolean; Msg : String) is
   begin
      if Condition then
         Put_Line("      PASS: " & Msg);
      else
         Put_Line("      FAIL: " & Msg);
         raise Program_Error with "Test failed: " & Msg;
      end if;
   end Assert;

   procedure Assert_Close (A, B : Complex; Msg : String) is
   begin
      Assert(abs(A.Re - B.Re) < Tolerance and abs(A.Im - B.Im) < Tolerance, Msg);
   end Assert_Close;

   Empty_Arr : Complex_Array (1 .. 0);
   Arr_1 : Complex_Array := ((1.0, 0.0), (1.0, 0.0), (1.0, 0.0), (1.0, 0.0));
   Res_1 : Complex_Array (0 .. 3);

   Arr_3 : Complex_Array := ((1.0, 0.0), (2.0, 0.0), (3.0, 0.0));
   Res_3, Res_3_Inv : Complex_Array (0 .. 2);

   Arr_CZT : Complex_Array := ((1.0, 0.0), (1.0, 0.0), (1.0, 0.0));
   Res_CZT : Complex_Array (0 .. 2);
begin
   Put_Line("=============================================");
   Put_Line("BLUESTEIN FFT / CZT V&V TEST SUITE RUNNER");
   Put_Line("=============================================");

   -- TEST 1
   Put_Line("TEST 1 - Forward FFT Functional Correctness (Power of 2)");
   Res_1 := Forward_FFT(Arr_1);
   Assert_Close(Res_1(0), (4.0, 0.0), "1.1 DC Component matches Sum");
   Assert_Close(Res_1(1), (0.0, 0.0), "1.2 AC Component 1 is Zero");
   Assert_Close(Res_1(2), (0.0, 0.0), "1.3 AC Component 2 is Zero");

   -- TEST 2
   Put_Line("TEST 2 - Inverse FFT Reversibility (Power of 2)");
   declare
      Inv_Res : Complex_Array := Inverse_FFT(Res_1);
   begin
      Assert_Close(Inv_Res(0), (1.0, 0.0), "2.1 Element 0 Recovered");
      Assert_Close(Inv_Res(1), (1.0, 0.0), "2.2 Element 1 Recovered");
      Assert_Close(Inv_Res(3), (1.0, 0.0), "2.3 Element 3 Recovered");
   end;

   -- TEST 3
   Put_Line("TEST 3 - Forward FFT Non-Power of Two (N=3)");
   Res_3 := Forward_FFT(Arr_3);
   Assert_Close(Res_3(0), (6.0, 0.0), "3.1 Sum of inputs equals X_0");
   Assert_Close(Res_3(1), (-1.5, 0.866), "3.2 Correct X_1 phase calculation");

   -- TEST 4
   Put_Line("TEST 4 - Inverse FFT Non-Power of Two (N=3)");
   Res_3_Inv := Inverse_FFT(Res_3);
   Assert_Close(Res_3_Inv(0), (1.0, 0.0), "4.1 X_0 perfectly recovered");
   Assert_Close(Res_3_Inv(1), (2.0, 0.0), "4.2 X_1 perfectly recovered");
   Assert_Close(Res_3_Inv(2), (3.0, 0.0), "4.3 X_2 perfectly recovered");

   -- TEST 5
   Put_Line("TEST 5 - Single Element Edge Case");
   declare
      Single : Complex_Array(0..0) := (0 => (42.0, 0.0));
      Res : Complex_Array := Forward_FFT(Single);
   begin
      Assert(Res'Length = 1, "5.1 Length remains 1");
      Assert_Close(Res(0), (42.0, 0.0), "5.2 Value passes through unmodified");
   end;

   -- TEST 6
   Put_Line("TEST 6 - Empty Input Safety Barrier");
   begin
      declare
         Discard : Complex_Array := Forward_FFT(Empty_Arr);
      begin
         Assert(False, "6.1 Should not be reached");
      end;
   exception
      when Invalid_Size =>
         Assert(True, "6.1 Invalid_Size gracefully raised on Empty Array");
   end;

   -- TEST 7
   Put_Line("TEST 7 - Chirp-Z General Transform Verification");
   -- Setting W=1, A=1 effectively sums the signal for all K
   Res_CZT := Chirp_Z_Transform(Arr_CZT, A => (1.0, 0.0), W => (1.0, 0.0), M_Out => 3);
   Assert_Close(Res_CZT(0), (3.0, 0.0), "7.1 CZT Element 0 matches sum");
   Assert_Close(Res_CZT(1), (3.0, 0.0), "7.2 CZT Element 1 matches sum");
   Assert_Close(Res_CZT(2), (3.0, 0.0), "7.3 CZT Element 2 matches sum");

   -- TEST 8
   Put_Line("TEST 8 - CZT DFT Alignment Verification");
   declare
      W_DFT : Complex := Compose_From_Polar(1.0, -2.0 * Pi / 3.0);
      Res_Align : Complex_Array := Chirp_Z_Transform(Arr_3, A => (1.0, 0.0), W => W_DFT, M_Out => 3);
   begin
      Assert_Close(Res_Align(0), Res_3(0), "8.1 CZT X_0 Matches standard DFT");
      Assert_Close(Res_Align(1), Res_3(1), "8.2 CZT X_1 Matches standard DFT");
      Assert_Close(Res_Align(2), Res_3(2), "8.3 CZT X_2 Matches standard DFT");
   end;

   -- TEST 9
   Put_Line("TEST 9 - Arbitrary Index Boundary Robustness");
   declare
      Weird_Indices : Complex_Array(10 .. 11) := ((5.0, 0.0), (2.0, 0.0));
      Res : Complex_Array := Forward_FFT(Weird_Indices);
   begin
      Assert(Res'Length = 2, "9.1 Correct output size");
      Assert_Close(Res(0), (7.0, 0.0), "9.2 Output 0 correct regardless of input index offset");
      Assert_Close(Res(1), (3.0, 0.0), "9.3 Output 1 correct regardless of input index offset");
   end;

   -- TEST 10
   Put_Line("TEST 10 - Radix-2 Internal Consistency checks");
   declare
      Bad_Len : Complex_Array(0..2) := ((1.0, 0.0), (1.0, 0.0), (1.0, 0.0));
   begin
      declare
         Discard : Complex_Array := Radix2_FFT(Bad_Len);
      begin
         Assert(False, "10.1 Should not be reached");
      end;
   exception
      when Invalid_Size =>
         Assert(True, "10.1 Radix-2 explicitly traps Non-Power-of-2");
   end;

   -- TEST 11
   Put_Line("TEST 11 - CZT Expanding Bounds Output M > N");
   declare
      Small : Complex_Array(0..1) := ((1.0, 0.0), (0.0, 0.0));
      Big_Out : Complex_Array := Chirp_Z_Transform(Small, A => (1.0, 0.0), W => (1.0, 0.0), M_Out => 5);
   begin
      Assert(Big_Out'Length = 5, "11.1 Generated M out points");
      Assert_Close(Big_Out(4), (1.0, 0.0), "11.2 Extrapolated point valid");
   end;

   -- TEST 12
   Put_Line("TEST 12 - Large Prime Size O(N Log N) Path (N=13)");
   declare
      Prime_Arr : Complex_Array(0..12) := (others => (1.0, 0.0));
      Res : Complex_Array := Forward_FFT(Prime_Arr);
   begin
      Assert_Close(Res(0), (13.0, 0.0), "12.1 DC is correctly 13");
      Assert_Close(Res(1), (0.0, 0.0), "12.2 AC bins accurately zeroed out for prime bounds");
   end;

   -- TEST 13
   Put_Line("TEST 13 - Zero Magnitude Power Base Protection");
   declare
      Base_Zero : Complex_Array := Chirp_Z_Transform(Arr_1, A => (0.0, 0.0), W => (0.0, 0.0), M_Out => 4);
   begin
      Assert(True, "13.1 CZT handles completely 0 base edge cases safely without math traps");
   end;
   
   Put_Line("=============================================");
   Put_Line("ALL TESTS PASSED SUCCESSFULLY");
   Put_Line("=============================================");
end Tests;
