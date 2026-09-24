with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with A_Law; use A_Law;

procedure Tests is

   -- Utility Assertion for Float Tolerance Check
   procedure Assert_Float_Eq (Actual, Expected, Tolerance : Float; Message : String) is
   begin
      Assert (abs (Actual - Expected) <= Tolerance,
         Message & " | Expected: " & Float'Image(Expected) & " Actual: " & Float'Image(Actual));
   end Assert_Float_Eq;

begin
   Put_Line ("======================================================");
   Put_Line (" A-Law V&V Test Suite");
   Put_Line (" Assumption: Code is Broken. Proving otherwise...");
   Put_Line ("======================================================");

   -- TEST 1: Continuous Function Correctness (Encoding Boundaries)
   Put_Line ("TEST 1 - Continuous Encode Boundaries");
   Put_Line ("  1.1 Assert Encode(0.0) = 0.0");
   Assert_Float_Eq (Float (Encode_Continuous(0.0)), 0.0, 0.0001, "Zero encoding failed");
   Put_Line ("      PASS");

   Put_Line ("  1.2 Assert Encode(1.0) = 1.0 (Maximum peak compression)");
   Assert_Float_Eq (Float (Encode_Continuous(1.0)), 1.0, 0.0001, "Max positive encoding failed");
   Put_Line ("      PASS");

   Put_Line ("  1.3 Assert Encode(-1.0) = -1.0 (Minimum peak compression)");
   Assert_Float_Eq (Float (Encode_Continuous(-1.0)), -1.0, 0.0001, "Min negative encoding failed");
   Put_Line ("      PASS");

   -- TEST 2: Continuous Function Correctness (Decoding Boundaries)
   Put_Line ("TEST 2 - Continuous Decode Boundaries");
   Put_Line ("  2.1 Assert Decode(0.0) = 0.0");
   Assert_Float_Eq (Float (Decode_Continuous(0.0)), 0.0, 0.0001, "Zero decoding failed");
   Put_Line ("      PASS");

   Put_Line ("  2.2 Assert Decode(1.0) = 1.0");
   Assert_Float_Eq (Float (Decode_Continuous(1.0)), 1.0, 0.0001, "Max positive decoding failed");
   Put_Line ("      PASS");

   Put_Line ("  2.3 Assert Decode(-1.0) = -1.0");
   Assert_Float_Eq (Float (Decode_Continuous(-1.0)), -1.0, 0.0001, "Min negative decoding failed");
   Put_Line ("      PASS");

   -- TEST 3: System Reliability (Continuous Mathematical Reversibility)
   Put_Line ("TEST 3 - Continuous Round-Trip (Identity Property)");
   Put_Line ("  3.1 Assert Decode(Encode(0.5)) ≈ 0.5 (Logarithmic Sector)");
   Assert_Float_Eq (Float (Decode_Continuous(Encode_Continuous(0.5))), 0.5, 0.0001, "Logarithmic sector failed");
   Put_Line ("      PASS");

   Put_Line ("  3.2 Assert Decode(Encode(-0.01)) ≈ -0.01 (Linear Sector below 1/A)");
   Assert_Float_Eq (Float (Decode_Continuous(Encode_Continuous(-0.01))), -0.01, 0.0001, "Linear sector failed");
   Put_Line ("      PASS");

   -- TEST 4: Discrete Specific Mappings (Validating G.711 Protocol Specs)
   Put_Line ("TEST 4 - Discrete Specific Encodes (Even-bit Toggle 0x55)");
   Put_Line ("  4.1 Assert Encode(0) = 0xD5");
   Assert (Encode_Discrete (0) = 16#D5#, "0 encoding failed (should be 128 XOR 85)");
   Put_Line ("      PASS");

   Put_Line ("  4.2 Assert Encode(-1) = 0x55");
   Assert (Encode_Discrete (-1) = 16#55#, "-1 encoding failed");
   Put_Line ("      PASS");

   Put_Line ("  4.3 Assert Encode(4095) = 0xAA (Highest positive clamping)");
   Assert (Encode_Discrete (4095) = 16#AA#, "Max peak encoding failed");
   Put_Line ("      PASS");
   
   Put_Line ("  4.4 Assert Encode(-4096) behaves correctly within 13-bit magnitude limits");
   Assert (Encode_Discrete (-4096) = 16#2A#, "Max negative boundary clamp failed");
   Put_Line ("      PASS");

   -- TEST 5: Discrete Decode Correctness (Step Centering Evaluation)
   Put_Line ("TEST 5 - Discrete Decode Specific Bytes");
   Put_Line ("  5.1 Assert Decode(0xD5) yields 1 (Quantized center of 0 magnitude)");
   Assert (Decode_Discrete (16#D5#) = 1, "Decode center offset failed");
   Put_Line ("      PASS");

   Put_Line ("  5.2 Assert Decode(0xAA) yields 4032 (Max chord reconstructed)");
   Assert (Decode_Discrete (16#AA#) = 4032, "Max chord extraction failed");
   Put_Line ("      PASS");

   -- TEST 6: Discrete Robustness and Tolerance (Quantization Error Modeling)
   Put_Line ("TEST 6 - Discrete Quantization Boundary Testing");
   Put_Line ("  6.1 Assert Decode(Encode(100)) falls in accurate error bounds (max 2 diff)");
   declare
      Orig : constant PCM_Sample := 100;
      Diff : constant Integer := abs(Integer(Decode_Discrete(Encode_Discrete(Orig))) - Integer(Orig));
   begin
      Assert (Diff <= 2, "Quantization delta out of step variance");
      Put_Line ("      PASS");
   end;
   
   Put_Line ("  6.2 Assert Decode(Encode(-1000)) falls in large step bounds (max 16 diff)");
   declare
      Orig : constant PCM_Sample := -1000;
      Diff : constant Integer := abs(Integer(Decode_Discrete(Encode_Discrete(Orig))) - Integer(Orig));
   begin
      Assert (Diff <= 16, "High-magnitude delta exceeds PCM threshold");
      Put_Line ("      PASS");
   end;

   Put_Line ("------------------------------------------------------");
   Put_Line ("✅ All 16 pessimistic assumptions disproven. System PASSES.");
end Tests;
