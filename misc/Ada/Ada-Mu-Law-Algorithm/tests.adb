-- tests.adb
-- Standalone test suite for Verification and Validation of the Mu_Law algorithm.
-- Philosophy: Assume the code is broken. Tests only PASS when disproving this assumption.

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Mu_Law; use Mu_Law;

procedure Tests is

   Margin_Of_Error : constant Float := 0.0001;

   -- Helper to check floating point equality within a tolerance margin
   function Approx_Equal (A, B : Float) return Boolean is
   begin
      return abs (A - B) <= Margin_Of_Error;
   end Approx_Equal;

begin
   Put_Line ("=======================================================");
   Put_Line ("            MU-LAW V&V TEST SUITE RUNNER               ");
   Put_Line ("=======================================================");
   Put_Line ("Assumption: The codebase is broken.");
   Put_Line ("Goal: Execute tests to disprove assumptions (PASS).");
   Put_Line ("");

   -- TEST 1
   Put_Line ("TEST 1 - Analog Encoding Baseline (Zero)");
   Put_Line ("  1.1 Assert encoding 0.0 equals 0.0");
   Assert (Encode_Continuous (0.0) = 0.0, "Zero encoding failed");
   Put_Line ("      PASS: Zero maps to zero correctly.");

   -- TEST 2
   Put_Line ("TEST 2 - Analog Encoding Positive Boundary");
   Put_Line ("  2.1 Assert encoding 1.0 equals 1.0");
   Assert (Encode_Continuous (1.0) = 1.0, "Positive boundary encoding failed");
   Put_Line ("      PASS: Positive maximum mapped correctly.");

   -- TEST 3
   Put_Line ("TEST 3 - Analog Encoding Negative Boundary");
   Put_Line ("  3.1 Assert encoding -1.0 equals -1.0");
   Assert (Encode_Continuous (-1.0) = -1.0, "Negative boundary encoding failed");
   Put_Line ("      PASS: Negative maximum mapped correctly.");

   -- TEST 4
   Put_Line ("TEST 4 - Analog Decoding Baseline (Zero)");
   Put_Line ("  4.1 Assert decoding 0.0 equals 0.0");
   Assert (Decode_Continuous (0.0) = 0.0, "Zero decoding failed");
   Put_Line ("      PASS: Zero restores to zero.");

   -- TEST 5
   Put_Line ("TEST 5 - Analog Mathematical Reversibility (Positive)");
   Put_Line ("  5.1 Assert Decode(Encode(0.5)) ~= 0.5");
   Assert (Approx_Equal (Float(Decode_Continuous(Encode_Continuous(0.5))), 0.5), "Positive Reversibility failed");
   Put_Line ("      PASS: Companding logic proved mathematically reversible.");

   -- TEST 6
   Put_Line ("TEST 6 - Analog Mathematical Reversibility (Negative)");
   Put_Line ("  6.1 Assert Decode(Encode(-0.33)) ~= -0.33");
   Assert (Approx_Equal (Float(Decode_Continuous(Encode_Continuous(-0.33))), -0.33), "Negative Reversibility failed");
   Put_Line ("      PASS: Companding logic symmetric for negative values.");

   -- TEST 7
   Put_Line ("TEST 7 - Invalid Compression Parameter Protection");
   Put_Line ("  7.1 Assert Mu=0.0 raises Invalid_Mu_Error exception");
   begin
      declare
         Dummy : Normalized_Signal;
      begin
         Dummy := Encode_Continuous (0.5, 0.0);
         Assert (False, "Exception was NOT raised for Mu=0.0");
      end;
   exception
      when Invalid_Mu_Error =>
         Put_Line ("      PASS: Handled zero division/invalid Mu parameter.");
   end;

   -- TEST 8
   Put_Line ("TEST 8 - Negative Compression Parameter Protection");
   Put_Line ("  8.1 Assert Mu=-255.0 raises Invalid_Mu_Error exception");
   begin
      declare
         Dummy : Normalized_Signal;
      begin
         Dummy := Decode_Continuous (0.5, -255.0);
         Assert (False, "Exception was NOT raised for negative Mu");
      end;
   exception
      when Invalid_Mu_Error =>
         Put_Line ("      PASS: Handled negative Mu parameter.");
   end;

   -- TEST 9
   Put_Line ("TEST 9 - Subtype Boundary Protection (Out of bounds)");
   Put_Line ("  9.1 Assert X=1.5 raises Constraint_Error before evaluation");
   begin
      declare
         -- Use a function to hide the static value from the compiler's constraint checker
         function Get_Bad_Value return Float is
         begin
            return 1.5;
         end Get_Bad_Value;
         
         Dummy : Normalized_Signal;
      begin
         Dummy := Encode_Continuous (Normalized_Signal(Get_Bad_Value));
         Assert (False, "Constraint_Error NOT raised for 1.5");
      end;
   exception
      when Constraint_Error =>
         Put_Line ("      PASS: Subtype constraints successfully prevent invalid signals.");
   end;

   -- TEST 10
   Put_Line ("TEST 10 - Digital Encoding Baseline (Zero)");
   Put_Line ("  10.1 Assert digital encode 0 equals 0");
   Assert (Encode_Digital (0) = 0, "Digital zero encoding failed");
   Put_Line ("      PASS: PCM digital zero compresses to 0.");

   -- TEST 11
   Put_Line ("TEST 11 - Digital Encoding Positive Max");
   Put_Line ("  11.1 Assert digital encode 8191 equals 127 (Max 8-bit val)");
   Assert (Encode_Digital (8191) = 127, "Digital max positive failed");
   Put_Line ("      PASS: Maximum PCM range correctly clamped to 127.");

   -- TEST 12
   Put_Line ("TEST 12 - Digital Encoding Negative Max");
   Put_Line ("  12.1 Assert digital encode -8192 equals -127 or -128");
   Assert (Encode_Digital (-8192) <= -127, "Digital max negative failed");
   Put_Line ("      PASS: Minimum PCM range clamped to negative bounds.");

   -- TEST 13
   Put_Line ("TEST 13 - Digital Decoding Baseline (Zero)");
   Put_Line ("  13.1 Assert digital decode 0 equals 0");
   Assert (Decode_Digital (0) = 0, "Digital zero decoding failed");
   Put_Line ("      PASS: Digital zero expands to PCM 0.");

   -- TEST 14
   Put_Line ("TEST 14 - Digital Companding Approximation Tolerance");
   Put_Line ("  14.1 Assert Decode(Encode(4096)) is within quantization error limits");
   declare
      Original    : constant PCM_14_Bit := 4096;
      Companded   : constant Mu_Law_8_Bit := Encode_Digital(Original);
      Expanded    : constant PCM_14_Bit := Decode_Digital(Companded);
      Error_Delta : constant Integer := abs (Integer(Original) - Integer(Expanded));
   begin
      -- In digital Mu-Law, higher amplitudes have higher quantization errors.
      -- A delta < 150 at 50% amplitude is mathematically expected due to 8-bit resolution
      Assert (Error_Delta < 150, "Quantization error exceeded mathematical limits");
      Put_Line ("      PASS: Acceptable quantization noise ratio proved valid.");
   end;

   -- TEST 15
   Put_Line ("TEST 15 - Sign preservation in Digital Domain");
   Put_Line ("  15.1 Assert Encode(-4096) is negative");
   Assert (Encode_Digital(-4096) < 0, "Sign bit lost in digital encode");
   Put_Line ("      PASS: Phase/Sign inversion avoided during transformation.");

   Put_Line ("=======================================================");
   Put_Line (" ALL ASSUMPTIONS DISPROVED - SYSTEM FUNCTIONING AS REQUIRED ");
   Put_Line ("=======================================================");

end Tests;
