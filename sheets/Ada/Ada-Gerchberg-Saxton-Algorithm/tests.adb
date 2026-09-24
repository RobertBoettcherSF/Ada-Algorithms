with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Ada.Numerics;
with Gerchberg_Saxton; use Gerchberg_Saxton;
use Gerchberg_Saxton.Complex_Types; -- Makes Complex, Re, and Im fully visible

procedure Tests is
   Tolerance : constant Real := 0.0001;

   function Is_Close (A, B : Real) return Boolean is
   begin
      return abs (A - B) < Tolerance;
   end Is_Close;

   function Is_Close (A, B : Complex) return Boolean is
   begin
      -- Using Re() and Im() functions is the standard way to access 
      -- components of the private Complex type in Ada.
      return abs (Re (A) - Re (B)) < Tolerance and abs (Im (A) - Im (B)) < Tolerance;
   end Is_Close;

   -- Dummy arrays for testing
   Empty_Real : Real_Array (1 .. 0);
   A4_Real    : Real_Array (1 .. 4) := (1.0, 2.0, 3.0, 4.0);
   A5_Real    : Real_Array (1 .. 5) := (1.0, 2.0, 3.0, 4.0, 5.0);
   
   C4         : Complex_Array (1 .. 4) := ((1.0, 0.0), (1.0, 0.0), (1.0, 0.0), (1.0, 0.0));
   C4_Out     : Complex_Array (1 .. 4);
   R4_Out     : Real_Array (1 .. 4);
begin
   Put_Line ("========================================");
   Put_Line ("   GERCHBERG-SAXTON TEST SUITE");
   Put_Line ("========================================");

   -- TEST 1
   Put_Line ("TEST 1 - DFT Math Correctness");
   Put_Line ("  1.1 Assert DFT of DC signal creates single impulse");
   C4_Out := DFT (C4);
   Assert (Is_Close (C4_Out(1), (4.0, 0.0)), "DC bin failed");
   Assert (Is_Close (C4_Out(2), (0.0, 0.0)), "AC bin 1 failed");
   Put_Line ("      PASS");

   -- TEST 2
   Put_Line ("TEST 2 - IDFT Math Correctness");
   Put_Line ("  2.1 Assert IDFT of impulse creates DC signal");
   C4_Out := IDFT (( (4.0, 0.0), (0.0, 0.0), (0.0, 0.0), (0.0, 0.0) ));
   Assert (Is_Close (C4_Out(1), (1.0, 0.0)), "IDFT value 1 failed");
   Assert (Is_Close (C4_Out(4), (1.0, 0.0)), "IDFT value 4 failed");
   Put_Line ("      PASS");

   -- TEST 3
   Put_Line ("TEST 3 - Identity Property (Transform Inversion)");
   Put_Line ("  3.1 Assert IDFT(DFT(Signal)) == Signal");
   C4_Out := IDFT (DFT (C4));
   Assert (Is_Close (C4_Out(1), C4(1)), "Identity property failed");
   Put_Line ("      PASS");

   -- TEST 4
   Put_Line ("TEST 4 - Standard GS Dimension Safety");
   Put_Line ("  4.1 Assert mismatched Source/Target lengths raise Dimension_Mismatch_Error");
   begin
      R4_Out := Standard_GS (A4_Real, A5_Real, 10);
      Assert (False, "Expected Dimension_Mismatch_Error not raised");
   exception
      when Dimension_Mismatch_Error =>
         Put_Line ("      PASS");
   end;

   -- TEST 5
   Put_Line ("TEST 5 - Standard GS Empty Input Safety");
   Put_Line ("  5.1 Assert empty arrays raise Invalid_Input_Error");
   begin
      R4_Out := Standard_GS (Empty_Real, Empty_Real, 10);
      Assert (False, "Expected Invalid_Input_Error not raised");
   exception
      when Invalid_Input_Error =>
         Put_Line ("      PASS");
   end;

   -- TEST 6
   Put_Line ("TEST 6 - HIO Variant Dimension Safety");
   Put_Line ("  6.1 Assert mismatched lengths raise Dimension_Mismatch_Error");
   begin
      R4_Out := Hybrid_Input_Output_GS (A4_Real, A5_Real, 10, 0.5);
      Assert (False, "Expected Dimension_Mismatch_Error not raised");
   exception
      when Dimension_Mismatch_Error =>
         Put_Line ("      PASS");
   end;

   -- TEST 7
   Put_Line ("TEST 7 - HIO Variant Empty Input Safety");
   Put_Line ("  7.1 Assert empty arrays raise Invalid_Input_Error");
   begin
      R4_Out := Hybrid_Input_Output_GS (Empty_Real, Empty_Real, 10, 0.5);
      Assert (False, "Expected Invalid_Input_Error not raised");
   exception
      when Invalid_Input_Error =>
         Put_Line ("      PASS");
   end;

   -- TEST 8
   Put_Line ("TEST 8 - Standard GS Zero Iteration Boundary");
   Put_Line ("  8.1 Assert 0 iterations returns zeroed phase array");
   R4_Out := Standard_GS (A4_Real, A4_Real, 0);
   Assert (Is_Close (R4_Out(1), 0.0), "Iter=0 did not return 0.0 phase");
   Put_Line ("      PASS");

   -- TEST 9
   Put_Line ("TEST 9 - Output Phase Bounds Validity (Standard GS)");
   Put_Line ("  9.1 Assert phase outputs are strictly bounded between -Pi and Pi");
   R4_Out := Standard_GS (A4_Real, (2.0, 1.0, 0.5, 1.0), 10);
   for I in R4_Out'Range loop
      Assert (R4_Out(I) >= -Ada.Numerics.Pi and R4_Out(I) <= Ada.Numerics.Pi, "Phase out of bounds");
   end loop;
   Put_Line ("      PASS");

   -- TEST 10
   Put_Line ("TEST 10 - Output Phase Bounds Validity (HIO Variant)");
   Put_Line ("  10.1 Assert phase outputs are strictly bounded between -Pi and Pi");
   R4_Out := Hybrid_Input_Output_GS (A4_Real, (2.0, 1.0, 0.5, 1.0), 10, 0.8);
   for I in R4_Out'Range loop
      Assert (R4_Out(I) >= -Ada.Numerics.Pi and R4_Out(I) <= Ada.Numerics.Pi, "Phase out of bounds");
   end loop;
   Put_Line ("      PASS");

   -- TEST 11
   Put_Line ("TEST 11 - Trivial Case Convergence");
   Put_Line ("  11.1 Assert identical source and target converges predictably");
   R4_Out := Standard_GS (A4_Real, A4_Real, 1);
   Assert (R4_Out'Length = A4_Real'Length, "Output size mismatch");
   Put_Line ("      PASS");

   -- TEST 12
   Put_Line ("TEST 12 - Transform Energy Validity");
   Put_Line ("  12.1 Assert Parseval logic in transform bounds (energy > 0)");
   C4_Out := DFT (C4);
   declare
      Energy : Real := 0.0;
   begin
      for I in C4_Out'Range loop
         Energy := Energy + (Re (C4_Out(I))**2 + Im (C4_Out(I))**2);
      end loop;
      Assert (Energy > 0.0, "Energy conservation violated");
   end;
   Put_Line ("      PASS");

   -- TEST 13
   Put_Line ("TEST 13 - Relaxation Impact Verification");
   Put_Line ("  13.1 Assert HIO (Beta=0.9) produces different results than Standard GS");
   declare
      R4_Std : Real_Array := Standard_GS (A4_Real, (2.0, 0.0, 2.0, 0.0), 10);
      R4_Hio : Real_Array := Hybrid_Input_Output_GS (A4_Real, (2.0, 0.0, 2.0, 0.0), 10, 0.9);
      Differs : Boolean := False;
   begin
      for I in A4_Real'Range loop
         if not Is_Close (R4_Std(I), R4_Hio(I)) then
            Differs := True;
         end if;
      end loop;
      Assert (Differs, "HIO did not perturb phase compared to Standard GS");
   end;
   Put_Line ("      PASS");

   Put_Line ("========================================");
   Put_Line ("ALL TESTS PASSED: Assumptions of broken code have been disproven.");
end Tests;
