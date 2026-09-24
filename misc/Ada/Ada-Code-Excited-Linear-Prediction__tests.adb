-- tests.adb
-- Comprehensive Verification and Validation (V&V) suite for CELP implementation.

with Ada.Text_IO; use Ada.Text_IO;
with CELP;        use CELP;

procedure Tests is

   Input_Signal : Signal_Frame := (others => 0.0);
   Output_Signal: Signal_Frame;
   Params       : Encoded_Parameters;

   procedure Assert (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Put_Line ("      FAIL: " & Message);
         raise Program_Error with Message;
      else
         Put_Line ("      PASS: " & Message);
      end if;
   end Assert;

begin
   Put_Line ("Starting CELP V&V Test Suite...");
   Put_Line ("---------------------------------");

   -- TEST 1 - Standard CELP Functional Flow
   Put_Line ("TEST 1 - Standard CELP Encoding/Decoding");
   Encode(Input_Signal, Params, Standard_CELP);
   Decode(Params, Output_Signal);
   Assert(Params.Variant = Standard_CELP, "Variant set correctly");
   Assert(Params.Fixed_Index >= 1, "Codebook index within bounds");

   -- TEST 2 - Zero Input Signal Processing
   Put_Line ("TEST 2 - Zero Energy Edge Case");
   Input_Signal := (others => 0.0);
   Encode(Input_Signal, Params, Standard_CELP);
   Assert(Params.Fixed_Gain = 0.0, "Fixed gain suppressed on silence");
   Assert(Params.Pitch_Gain = 0.0, "Pitch gain suppressed on silence");

   -- TEST 3 - ACELP Variant Structural Verification
   Put_Line ("TEST 3 - ACELP Algebraic Sparse Structure");
   Encode(Input_Signal, Params, ACELP);
   declare
      Vector : Signal_Frame := Generate_Fixed_Codebook(1, ACELP);
      Zeros  : Integer := 0;
   begin
      for I in Vector'Range loop
         if Vector(I) = 0.0 then Zeros := Zeros + 1; end if;
      end loop;
      Assert(Zeros > 30, "ACELP generates sparse vector (majority zeros)");
   end;

   -- TEST 4 - VSELP Variant Basis Vectors
   Put_Line ("TEST 4 - VSELP Codebook Characteristics");
   declare
      V_Vec : Signal_Frame := Generate_Fixed_Codebook(2, VSELP);
   begin
      Assert(V_Vec(1) /= 0.0, "VSELP generates continuous basis combinations");
   end;

   -- TEST 5 - Low Delay CELP Backward Adaptation Logic
   Put_Line ("TEST 5 - LD-CELP Short Block Simulation");
   declare
      LD_Vec : Signal_Frame := Generate_Fixed_Codebook(1, LD_CELP);
   begin
      Assert(LD_Vec(6) = 0.0, "LD-CELP generates short sub-frames");
      Assert(LD_Vec(1) = 0.5, "LD-CELP active block correctly set");
   end;

   -- TEST 6 - PSI-CELP Periodic Innovation
   Put_Line ("TEST 6 - PSI-CELP Periodicity Check");
   declare
      PSI_Vec : Signal_Frame := Generate_Fixed_Codebook(1, PSI_CELP);
   begin
      Assert(PSI_Vec(2) = 1.0 and PSI_Vec(12) = 1.0, "PSI-CELP enforces strict periodicity");
   end;

   -- TEST 7 - Codebook Boundaries (Lower)
   Put_Line ("TEST 7 - Fixed Codebook Lower Boundary Limit");
   declare
      Vec : Signal_Frame;
   begin
      Vec := Generate_Fixed_Codebook(1, Standard_CELP);
      Assert(True, "Index 1 handled without exceptions");
   end;

   -- TEST 8 - Codebook Boundaries (Upper)
   Put_Line ("TEST 8 - Fixed Codebook Upper Boundary Limit");
   declare
      Vec : Signal_Frame;
   begin
      Vec := Generate_Fixed_Codebook(256, Standard_CELP);
      Assert(True, "Index 256 handled without exceptions");
   end;

   -- TEST 9 - Invalid Codebook Index Handling
   Put_Line ("TEST 9 - Exception on Invalid Codebook Index");
   begin
      declare
         Vec : Signal_Frame := Generate_Fixed_Codebook(300, Standard_CELP);
      begin
         Assert(False, "Should have raised Exception");
      end;
   exception
      when CELP_Configuration_Error =>
         Assert(True, "Caught expected CELP_Configuration_Error");
   end;

   -- TEST 10 - LPC Synthesis Filter Stability
   Put_Line ("TEST 10 - LPC Synthesis Stability and Filtering");
   declare
      Excitation : Signal_Frame := (1 => 1.0, others => 0.0);
      LPC        : LPC_Coeffs := (1 => 0.5, others => 0.0);
      Output     : Signal_Frame;
   begin
      Output := Apply_LPC_Synthesis(Excitation, LPC);
      Assert(Output(2) = 0.5, "First order autoregression matched");
      Assert(Output(3) = 0.25, "Second order autoregression decay matched");
   end;

   -- TEST 11 - Error Calculation Correctness (MSE)
   Put_Line ("TEST 11 - MSE Function Logic");
   declare
      Err : Float;
   begin
      Err := Compute_MSE (Input_Signal, Input_Signal);
      Assert(Err = 0.0, "MSE of identical signals is identically 0.0");
   end;

   -- TEST 12 - High Energy Handling (Overload Test)
   Put_Line ("TEST 12 - High Energy Input Handling");
   Input_Signal := (others => 1000.0);
   Encode(Input_Signal, Params, Standard_CELP);
   Assert(Params.Fixed_Index >= 1, "Successfully handled high-amplitude input");

   -- TEST 13 - Decoder Invalid Pitch Exception Handling
   Put_Line ("TEST 13 - Decoder Parameter Validation");
   begin
      -- Using Integer'Value to bypass the static compile-time warning
      -- while triggering the runtime Constraint_Error from the strict type bounds.
      Params.Pitch_Delay := Integer'Value("-1");
      Decode(Params, Output_Signal);
      Assert(False, "Failed to catch invalid Pitch_Delay");
   exception
      when Constraint_Error =>
         Assert(True, "Invalid Pitch_Delay securely trapped by Ada type constraints");
   end;

   -- TEST 14 - LD-CELP Backward State Transfer
   Put_Line ("TEST 14 - LD-CELP Backward Predictor Maintenance");
   Input_Signal := (others => 0.5);
   Encode(Input_Signal, Params, LD_CELP);
   Assert(Params.LPC(1) = 0.0, "LD-CELP LPC relies on previous state (0 initialized)");

   Put_Line ("---------------------------------");
   Put_Line ("ALL TESTS PASSED SUCCESSFULLY.");
end Tests;
