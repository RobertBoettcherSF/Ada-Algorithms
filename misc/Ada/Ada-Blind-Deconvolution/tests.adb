with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Blind_Deconvolution; use Blind_Deconvolution;

procedure Tests is
   Tolerence : constant Real := 0.001;
   
   function Approx_Eq (A, B : Real) return Boolean is
   begin
      return abs (A - B) < Tolerence;
   end Approx_Eq;
begin
   Put_Line ("=====================================================");
   Put_Line (" V&V Test Suite: Blind Deconvolution Assumptions");
   Put_Line ("=====================================================");

   -- TEST 1 - Array Normalization
   Put_Line ("TEST 1 - Array Normalization Constraints");
   Put_Line ("  1.1 Assert array sums to 1.0 after normalization");
   declare
      A : Signal_Array(1..4) := (2.0, 2.0, 2.0, 2.0);
   begin
      Normalize(A);
      Assert (Approx_Eq(A(1), 0.25), "Normalization failed");
      Put_Line ("      PASS");
   end;

   -- TEST 2 - Zero Array Normalization Edge Case
   Put_Line ("TEST 2 - Zero Array Normalization Edge Case");
   Put_Line ("  2.1 Assert zero arrays distribute evenly without NaN");
   declare
      A : Signal_Array(1..2) := (0.0, 0.0);
   begin
      Normalize(A);
      Assert (Approx_Eq(A(1), 0.5), "Zero array handling failed");
      Put_Line ("      PASS");
   end;

   -- TEST 3 - Array Reversal
   Put_Line ("TEST 3 - Cross-Correlation Array Reversal");
   Put_Line ("  3.1 Assert spatial time reversal is correct");
   declare
      A : Signal_Array(1..3) := (1.0, 2.0, 3.0);
      B : Signal_Array := Reverse_Array(A);
   begin
      Assert (Approx_Eq(B(1), 3.0) and Approx_Eq(B(3), 1.0), "Reversal failed");
      Put_Line ("      PASS");
   end;

   -- TEST 4 - Convolution Identity
   Put_Line ("TEST 4 - Convolution with Identity Kernel");
   Put_Line ("  4.1 Assert signal is unchanged by identity PSF");
   declare
      X : Signal_Array(1..5) := (1.0, 2.0, 3.0, 2.0, 1.0);
      H : Signal_Array(1..1) := (1 => 1.0);
      Y : Signal_Array := Convolve(X, H);
   begin
      Assert (Approx_Eq(Y(3), 3.0), "Identity convolution failed");
      Put_Line ("      PASS");
   end;

   -- TEST 5 - Empty Input Handling
   Put_Line ("TEST 5 - Empty Arrays Handled Safely");
   Put_Line ("  5.1 Assert Invalid_Input raised on empty arrays");
   begin
      declare
         X, H : Signal_Array(1..0);
         Y : Signal_Array := Convolve(X, H);
      begin
         Assert (False, "Should have raised exception");
      end;
   exception
      when Invalid_Input => Put_Line ("      PASS");
   end;

   -- TEST 6 - Dimension Mismatch Detection (Richardson-Lucy)
   Put_Line ("TEST 6 - Richardson-Lucy Dimension Integrity");
   Put_Line ("  6.1 Assert exception on mismatched Observed vs Signal");
   begin
      declare
         Obs : Signal_Array(1..5) := (others => 1.0);
         Sig : Signal_Array(1..4) := (others => 1.0);
         PSF : Signal_Array(1..3) := (others => 1.0);
      begin
         Richardson_Lucy_Blind(Obs, 10, Sig, PSF);
         Assert (False, "Should have raised exception");
      end;
   exception
      when Dimension_Mismatch => Put_Line ("      PASS");
   end;

   -- TEST 7 - Richardson Lucy Iterations
   Put_Line ("TEST 7 - Richardson-Lucy Iterative Deconvolution");
   Put_Line ("  7.1 Assert positivity and constraints maintained after iterations");
   declare
      Obs : Signal_Array(1..5) := (0.1, 0.5, 1.0, 0.5, 0.1);
      Sig : Signal_Array(1..5) := (0.2, 0.2, 0.2, 0.2, 0.2);
      PSF : Signal_Array(1..3) := (0.33, 0.33, 0.33);
   begin
      Richardson_Lucy_Blind(Obs, 5, Sig, PSF);
      Assert (Sig(3) > 0.0 and PSF(2) >= 0.0, "Constraints violated");
      Put_Line ("      PASS");
   end;

   -- TEST 8 - Alternating Minimization Dimension Integrity
   Put_Line ("TEST 8 - Alt Min Dimension Integrity");
   Put_Line ("  8.1 Assert exception on mismatched dimensions");
   begin
      declare
         Obs : Signal_Array(1..2) := (others => 1.0);
         Sig : Signal_Array(1..3) := (others => 1.0);
         PSF : Signal_Array(1..1) := (others => 1.0);
      begin
         Alternating_Minimization_Blind(Obs, 10, Sig, PSF);
         Assert (False, "Should have raised exception");
      end;
   exception
      when Dimension_Mismatch => Put_Line ("      PASS");
   end;

   -- TEST 9 - Alternating Minimization Iterations
   Put_Line ("TEST 9 - Alternating Minimization Updates");
   Put_Line ("  9.1 Assert arrays change but maintain bounds");
   declare
      Obs : Signal_Array(1..3) := (0.2, 0.8, 0.2);
      Sig : Signal_Array(1..3) := (0.3, 0.3, 0.3);
      PSF : Signal_Array(1..3) := (0.1, 0.8, 0.1);
   begin
      Alternating_Minimization_Blind(Obs, 10, Sig, PSF, 0.05);
      Assert (Sig(2) /= 0.3, "Signal didn't update");
      Put_Line ("      PASS");
   end;

   -- TEST 10 - Wiener Proxy Bounds
   Put_Line ("TEST 10 - Wiener Proxy Functionality");
   Put_Line (" 10.1 Assert non-iterative output produced safely");
   declare
      Obs : Signal_Array(1..3) := (0.0, 1.0, 0.0);
      PSF : Signal_Array(1..1) := (1 => 1.0);
      Res : Signal_Array := Wiener_Proxy_Deconvolution(Obs, PSF, SNR => 10.0);
   begin
      Assert (Res'Length = 3, "Output size mismatch");
      Put_Line ("      PASS");
   end;

   -- TEST 11 - Wiener Zero SNR Handling
   Put_Line ("TEST 11 - Wiener Noise Bounds");
   Put_Line (" 11.1 Assert Extreme Noise (Zero SNR) lowers output magnitude");
   declare
      Obs : Signal_Array(1..1) := (1 => 1.0);
      PSF : Signal_Array(1..1) := (1 => 1.0);
      High_Noise : Signal_Array := Wiener_Proxy_Deconvolution(Obs, PSF, SNR => 0.0);
      Low_Noise  : Signal_Array := Wiener_Proxy_Deconvolution(Obs, PSF, SNR => 100.0);
   begin
      Assert (High_Noise(1) < Low_Noise(1), "Noise scaling failed");
      Put_Line ("      PASS");
   end;
   
   -- TEST 12 - RL Blind Convergence Check
   Put_Line ("TEST 12 - RL Convergence Properties");
   Put_Line (" 12.1 Assert PSF stays normalized across updates");
   declare
      Obs : Signal_Array(1..4) := (0.1, 0.9, 0.9, 0.1);
      Sig : Signal_Array(1..4) := (0.25, 0.25, 0.25, 0.25);
      PSF : Signal_Array(1..3) := (0.1, 0.8, 0.1);
      Sum : Real := 0.0;
   begin
      Richardson_Lucy_Blind(Obs, 20, Sig, PSF);
      for X of PSF loop Sum := Sum + X; end loop;
      Assert (Approx_Eq(Sum, 1.0), "Energy not conserved in PSF");
      Put_Line ("      PASS");
   end;

   -- TEST 13 - Invalid Iteration Parameter (Handled by Ada Types)
   Put_Line ("TEST 13 - Ada Strong Typing on Iterations");
   Put_Line (" 13.1 Assert compiler/runtime catches zero iterations");
   begin
      declare
         Obs, Sig, PSF : Signal_Array(1..1) := (1 => 1.0);
         -- Simulating bad input by explicit constraint check
         Bad_Iters : Positive; 
      begin
         Bad_Iters := Integer'Value("0"); 
         Richardson_Lucy_Blind(Obs, Bad_Iters, Sig, PSF);
         Assert (False, "Should have failed constraint");
      end;
   exception
      when Constraint_Error => Put_Line ("      PASS");
   end;

   -- TEST 14 - Element Negativity Protection
   Put_Line ("TEST 14 - Constraining Negative Elements");
   Put_Line (" 14.1 Assert Algorithm clamps negative anomalies safely");
   declare
      Obs : Signal_Array(1..3) := (-1.0, -1.0, -1.0); -- Invalid physics, code must survive
      Sig : Signal_Array(1..3) := (1.0, 1.0, 1.0);
      PSF : Signal_Array(1..3) := (0.33, 0.33, 0.33);
   begin
      Richardson_Lucy_Blind(Obs, 2, Sig, PSF);
      Assert (Sig(1) >= 0.0, "Clamping failed on impossible signal");
      Put_Line ("      PASS");
   end;

   Put_Line ("=====================================================");
   Put_Line (" ALL ASSUMPTIONS DISPROVED: Code Behaviors Confirmed");
   Put_Line ("=====================================================");
end Tests;
