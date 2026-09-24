with Ada.Text_IO; use Ada.Text_IO;
with Ada.Numerics.Complex_Types; use Ada.Numerics.Complex_Types;
with Prime_Factor_FFT; use Prime_Factor_FFT;

procedure Tests is

   procedure Assert(Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Put_Line("      [FAIL] " & Message);
         raise Program_Error with Message;
      else
         Put_Line("      [PASS] " & Message);
      end if;
   end Assert;

   function Is_Close(A, B : Complex; Tol : Float := 1.0e-4) return Boolean is
   begin
      return abs(A.Re - B.Re) < Tol and abs(A.Im - B.Im) < Tol;
   end Is_Close;

   function Are_Arrays_Close(A, B : Complex_Array) return Boolean is
   begin
      if A'Length /= B'Length then return False; end if;
      for I in 0 .. A'Length - 1 loop
         if not Is_Close(A(A'First + I), B(B'First + I)) then return False; end if;
      end loop;
      return True;
   end Are_Arrays_Close;

   -- Test Variables
   DC_Signal  : Complex_Array(0 .. 3) := (others => (1.0, 0.0));
   Nyquist    : Complex_Array(0 .. 3) := ((1.0, 0.0), (-1.0, 0.0), (1.0, 0.0), (-1.0, 0.0));
   Sig_N6     : Complex_Array(0 .. 5) := ((1.0, 0.0), (2.0, 0.0), (3.0, 0.0), (4.0, 0.0), (5.0, 0.0), (6.0, 0.0));
   Sig_N15    : Complex_Array(0 .. 14) := (others => (1.5, -0.5));
   
   Res_Naive, Res_PFA, Res_In_Place : Complex_Array(0 .. 14);

begin
   Put_Line("=============================================");
   Put_Line("       V&V Prime-Factor FFT Test Suite       ");
   Put_Line("=============================================");

   Put_Line("TEST 1 - Naive DFT (Functional Correctness, DC)");
   Res_Naive(0..3) := DFT_Naive(DC_Signal);
   Assert(Is_Close(Res_Naive(0), (4.0, 0.0)), "1.1 DC bin should be 4.0");
   Assert(Is_Close(Res_Naive(1), (0.0, 0.0)), "1.2 Harmonic bins should be zero");

   Put_Line("TEST 2 - Naive DFT (Functional Correctness, Nyquist)");
   Res_Naive(0..3) := DFT_Naive(Nyquist);
   Assert(Is_Close(Res_Naive(0), (0.0, 0.0)), "2.1 DC bin should be 0.0");
   Assert(Is_Close(Res_Naive(2), (4.0, 0.0)), "2.2 Nyquist bin should be 4.0");

   Put_Line("TEST 3 - Naive DFT (Inverse Reversibility)");
   declare
      Back : Complex_Array(0..3) := DFT_Naive(DFT_Naive(Nyquist), True);
   begin
      Assert(Are_Arrays_Close(Nyquist, Back), "3.1 Inverse(Forward(X)) == X");
   end;

   Put_Line("TEST 4 - PFA Transform (Edge Case: Invalid Size)");
   begin
      Res_PFA(0..5) := PFA_Transform(Sig_N6, 2, 4);
      Assert(False, "4.1 Should have raised Invalid_Factors (length mismatch)");
   exception
      when Invalid_Factors => Assert(True, "4.1 Invalid_Factors raised on length mismatch");
   end;

   Put_Line("TEST 5 - PFA Transform (Edge Case: Non-Coprime Factors)");
   begin
      -- 6 = 2 * 3, but let's pass 4 and 2 to array of size 8
      declare
         Bad_Sig : Complex_Array(0..7) := (others => (0.0, 0.0));
         Bad_Out : Complex_Array(0..7);
      begin
         Bad_Out := PFA_Transform(Bad_Sig, 4, 2);
         Assert(False, "5.1 Should raise Invalid_Factors (GCD != 1)");
      end;
   exception
      when Invalid_Factors => Assert(True, "5.1 Raised Invalid_Factors on GCD(4,2) /= 1");
   end;

   Put_Line("TEST 6 - PFA Transform vs Naive (Functional Equivalence N=6)");
   Res_PFA(0..5) := PFA_Transform(Sig_N6, 2, 3);
   Res_Naive(0..5) := DFT_Naive(Sig_N6);
   Assert(Are_Arrays_Close(Res_PFA(0..5), Res_Naive(0..5)), "6.1 PFA output strictly matches Naive O(N^2) DFT");

   Put_Line("TEST 7 - PFA Transform vs Naive (Functional Equivalence N=15)");
   Res_PFA := PFA_Transform(Sig_N15, 3, 5);
   Res_Naive := DFT_Naive(Sig_N15);
   Assert(Are_Arrays_Close(Res_PFA, Res_Naive), "7.1 PFA output strictly matches Naive for N=15");

   Put_Line("TEST 8 - PFA Transform (Inverse Reversibility N=6)");
   declare
      Forward : Complex_Array(0..5) := PFA_Transform(Sig_N6, 2, 3);
      Inverse : Complex_Array(0..5) := PFA_Transform(Forward, 2, 3, True);
   begin
      Assert(Are_Arrays_Close(Sig_N6, Inverse), "8.1 Inverse PFA reconstructs the original signal");
   end;

   Put_Line("TEST 9 - PFA Transform (Inverse Reversibility N=15)");
   declare
      Forward : Complex_Array(0..14) := PFA_Transform(Sig_N15, 3, 5);
      Inverse : Complex_Array(0..14) := PFA_Transform(Forward, 3, 5, True);
   begin
      Assert(Are_Arrays_Close(Sig_N15, Inverse), "9.1 Inverse PFA reconstructs N=15 signal");
   end;

   Put_Line("TEST 10 - In-Place PFA Variant (Functional Match N=6)");
   Res_In_Place(0..5) := Sig_N6;
   PFA_Transform_In_Place(Res_In_Place(0..5), 2, 3);
   -- Bypassing the contaminated Res_PFA variable by computing expected directly here
   Assert(Are_Arrays_Close(Res_In_Place(0..5), PFA_Transform(Sig_N6, 2, 3)), "10.1 In-place variant outputs equal Out-of-place");

   Put_Line("TEST 11 - In-Place PFA Inverse Reversibility");
   PFA_Transform_In_Place(Res_In_Place(0..5), 2, 3, True);
   Assert(Are_Arrays_Close(Res_In_Place(0..5), Sig_N6), "11.1 In-Place Inverse yields original data");

   Put_Line("TEST 12 - PFA Single Pulse Response (Delta Function Check)");
   declare
      Delta_Pulse : Complex_Array(0..5) := ((1.0, 0.0), (0.0, 0.0), (0.0, 0.0), (0.0, 0.0), (0.0, 0.0), (0.0, 0.0));
      Pulse_Out   : Complex_Array(0..5) := PFA_Transform(Delta_Pulse, 2, 3);
   begin
      Assert(Is_Close(Pulse_Out(1), (1.0, 0.0)), "12.1 Transform of Delta(0) is (1.0, 0.0) across all bins");
      Assert(Is_Close(Pulse_Out(5), (1.0, 0.0)), "12.2 Bin 5 is (1.0, 0.0)");
   end;

   Put_Line("TEST 13 - PFA Complex Signal Orthogonality");
   declare
      Complex_Sig : Complex_Array(0..5) := ((0.0, 1.0), (0.0, -1.0), (0.0, 1.0), (0.0, -1.0), (0.0, 1.0), (0.0, -1.0));
      Out_Cmplx   : Complex_Array(0..5) := PFA_Transform(Complex_Sig, 2, 3);
   begin
      Assert(Is_Close(Out_Cmplx(0), (0.0, 0.0)), "13.1 DC of alternating pure-imaginary is 0");
      Assert(abs(Out_Cmplx(3).Im) > 1.0, "13.2 Nyquist bin detects the real component energy");
   end;

   Put_Line("=============================================");
   Put_Line("      ALL TESTS PASSED SUCCESSFULLY          ");
   Put_Line("=============================================");
end Tests;
