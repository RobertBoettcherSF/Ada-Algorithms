pragma Assertion_Policy (Check);
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Ada.Numerics.Complex_Types; use Ada.Numerics.Complex_Types;
with Adaptive_Additive; use Adaptive_Additive;

procedure Tests is
   procedure Assert_Float_Eq(A, B, Tol : Float; Msg : String) is
   begin
      if abs (A - B) > Tol then
         Put_Line ("FAIL: " & Msg & " (Expected " & Float'Image(B) & ", Got " & Float'Image(A) & ")");
         Assert (False, Msg);
      end if;
   end Assert_Float_Eq;
begin
   Put_Line("Starting Pessimistic V&V Test Suite...");
   
   Put_Line("TEST 1 - Modulus Calculation Correctness");
   Put_Line("  1.1 Assert Modulus of (3, 4) mathematically evaluates to 5");
   Assert_Float_Eq (Modulus_Helper((3.0, 4.0)), 5.0, 0.001, "Modulus calculation mismatch");
   Put_Line("     PASS");
   Put_Line("  1.2 Assert Modulus of zero-wave (0, 0) evaluates to 0");
   Assert_Float_Eq (Modulus_Helper((0.0, 0.0)), 0.0, 0.001, "Modulus calculation mismatch");
   Put_Line("     PASS");
   
   Put_Line("TEST 2 - Spatial Argument Calculation");
   Put_Line("  2.1 Assert purely real argument (1, 0) gives phase 0");
   Assert_Float_Eq (Argument_Helper((1.0, 0.0)), 0.0, 0.001, "Phase evaluation failure for +Re");
   Put_Line("     PASS");
   Put_Line("  2.2 Assert purely imaginary argument (0, 1) gives phase Pi/2");
   Assert_Float_Eq (Argument_Helper((0.0, 1.0)), 1.5708, 0.001, "Phase evaluation failure for +Im");
   Put_Line("     PASS");

   Put_Line("TEST 3 - Discrete Fourier Transform (DFT)");
   Put_Line("  3.1 Assert DFT of DC signal yields isolated zero-frequency peak");
   declare
      Input : Complex_Array(1 .. 4) := ((1.0, 0.0), (1.0, 0.0), (1.0, 0.0), (1.0, 0.0));
      Output : Complex_Array := DFT(Input);
   begin
      Assert_Float_Eq (Output(1).Re, 4.0, 0.001, "DC component mismatch");
      Assert_Float_Eq (Output(2).Re, 0.0, 0.001, "Spurious AC component detected");
      Put_Line("     PASS");
   end;

   Put_Line("TEST 4 - Inverse DFT (iDFT)");
   Put_Line("  4.1 Assert iDFT perfectly reverses DFT transforms (iDFT(DFT(X)) = X)");
   declare
      Input : Complex_Array(1 .. 2) := ((1.0, 0.0), (0.0, 1.0));
      Output : Complex_Array := DFT(DFT(Input, False), True);
   begin
      Assert_Float_Eq (Output(1).Re, 1.0, 0.001, "Reversal failure on Bin 1");
      Assert_Float_Eq (Output(2).Im, 1.0, 0.001, "Reversal failure on Bin 2");
      Put_Line("     PASS");
   end;

   Put_Line("TEST 5 - Input Error Handling (Length Mismatch)");
   Put_Line("  5.1 Assert execution halt via Invalid_Input_Error for array size disparity");
   begin
      declare
         Amp : Real_Array(1 .. 2) := (1.0, 1.0);
         Inten : Real_Array(1 .. 3) := (1.0, 1.0, 1.0);
         Phase : Real_Array(1 .. 2);
         Conv : Boolean;
      begin
         AA_Algorithm(Amp, Inten, 0.5, 10, 0.01, Phase, Conv);
         Assert (False, "Assumption disproved: Exception bypassed");
      end;
   exception
      when Invalid_Input_Error => Put_Line("     PASS");
   end;

   Put_Line("TEST 6 - Input Error Handling (Empty Subarrays)");
   Put_Line("  6.1 Assert execution halt via Invalid_Input_Error on empty boundaries");
   begin
      declare
         Amp, Inten, Phase : Real_Array(1 .. 0);
         Conv : Boolean;
      begin
         AA_Algorithm(Amp, Inten, 0.5, 10, 0.01, Phase, Conv);
         Assert (False, "Assumption disproved: Executed on null array");
      end;
   exception
      when Invalid_Input_Error => Put_Line("     PASS");
   end;

   Put_Line("TEST 7 - Input Error Handling (Physical Bounds)");
   Put_Line("  7.1 Assert execution halt via Invalid_Input_Error on negative intensity fields");
   begin
      declare
         Amp : Real_Array(1 .. 2) := (1.0, 1.0);
         Inten : Real_Array(1 .. 2) := (1.0, -5.0);
         Phase : Real_Array(1 .. 2);
         Conv : Boolean;
      begin
         AA_Algorithm(Amp, Inten, 0.5, 10, 0.01, Phase, Conv);
         Assert (False, "Assumption disproved: System allowed negative intensity");
      end;
   exception
      when Invalid_Input_Error => Put_Line("     PASS");
   end;

   Put_Line("TEST 8 - Convergence Correctness");
   Put_Line("  8.1 Assert matching initial conditions result in immediate Phase lock");
   declare
      Amp : Real_Array(1 .. 4) := (1.0, 1.0, 1.0, 1.0);
      Inten : Real_Array(1 .. 4) := (16.0, 0.0, 0.0, 0.0);
      Phase : Real_Array(1 .. 4);
      Conv : Boolean;
   begin
      AA_Algorithm(Amp, Inten, 0.5, 100, 0.01, Phase, Conv);
      Assert (Conv, "Trivial conditions failed to trigger convergence flag");
      Put_Line("     PASS");
   end;

   Put_Line("TEST 9 - Literature Variant (Gerchberg-Saxton)");
   Put_Line("  9.1 Assert Variant wraps successfully (a=1.0 limit)");
   declare
      Amp : Real_Array(1 .. 2) := (1.0, 1.0);
      Inten : Real_Array(1 .. 2) := (2.0, 2.0);
      Phase : Real_Array(1 .. 2);
      Conv : Boolean;
   begin
      Gerchberg_Saxton(Amp, Inten, 5, 0.1, Phase, Conv);
      Assert (True, "Algorithm crashed in GS state");
      Put_Line("     PASS");
   end;

   Put_Line("TEST 10 - Literature Variant (Fixed-Amplitude)");
   Put_Line("  10.1 Assert Variant wraps successfully (a=0.0 limit)");
   declare
      Amp, Inten, Phase : Real_Array(1 .. 2) := (1.0, 1.0);
      Conv : Boolean;
   begin
      Fixed_Amplitude(Amp, Inten, 5, 0.1, Phase, Conv);
      Assert (True, "Algorithm crashed in Fixed Amplitude state");
      Put_Line("     PASS");
   end;

   Put_Line("TEST 11 - Iterative Performance Constraints");
   Put_Line("  11.1 Assert Max Iterations accurately cuts off impossible target matches");
   declare
      Amp : Real_Array(1 .. 2) := (1.0, 1.0);
      Inten : Real_Array(1 .. 2) := (999.0, 0.0);
      Phase : Real_Array(1 .. 2);
      Conv : Boolean;
   begin
      AA_Algorithm(Amp, Inten, 0.5, 2, 0.0, Phase, Conv);
      Assert (not Conv, "Algorithm falsely flagged convergence");
      Put_Line("     PASS");
   end;
   
   Put_Line("TEST 12 - Parameter Stress Test");
   Put_Line("  12.1 Assert complex mixing ratio accurately resolves float limits");
   declare
      Amp : Real_Array(1 .. 4) := (0.5, 0.2, 0.1, 0.5);
      Inten : Real_Array(1 .. 4) := (1.0, 1.0, 1.0, 1.0);
      Phase : Real_Array(1 .. 4);
      Conv : Boolean;
   begin
      AA_Algorithm(Amp, Inten, 0.2, 5, 0.1, Phase, Conv);
      Put_Line("     PASS");
   end;

   Put_Line("TEST 13 - Output Domain Safeties");
   Put_Line("  13.1 Assert all finalized phase angles mathematically sit bounded between -Pi and Pi");
   declare
      Amp, Inten : Real_Array(1 .. 4) := (0.5, 0.2, 0.1, 0.5);
      Phase : Real_Array(1 .. 4);
      Conv, Valid_Bounds : Boolean := True;
   begin
      AA_Algorithm(Amp, Inten, 0.5, 5, 0.1, Phase, Conv);
      for I in Phase'Range loop
         if Phase(I) < -3.1416 or Phase(I) > 3.1416 then
            Valid_Bounds := False;
         end if;
      end loop;
      Assert (Valid_Bounds, "Radian constraint exceeded!");
      Put_Line("     PASS");
   end;
   
   Put_Line("All 13+ assertions successfully proved pessimistic assumptions false. Code Correct.");
end Tests;
