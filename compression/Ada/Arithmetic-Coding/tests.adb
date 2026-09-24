-- tests.adb
-- Validation and Verification (V&V) suite.
-- Philosophy: Assume the code is fundamentally broken, insecure, or fails at boundaries.
-- A "PASS" output implies the negative assumption was proven strictly false.

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Arithmetic_Coding; use Arithmetic_Coding;

procedure Tests is
   -- Helper variables
   Empty_Bits : constant Bit_Stream (1 .. 0) := (others => 0);
   Small_Str  : constant String := "WIKI";
   Long_Str   : String (1 .. 1000) := (others => 'A');
   Model      : Static_Model;
begin
   Put_Line ("Starting V&V Test Suite for Arithmetic Coding...");
   Put_Line ("------------------------------------------------");

   -- TEST 1 - Functionality: Static Model Generation handles Empty Inputs incorrectly
   Put_Line ("TEST 1 - Static Model generation on Empty String");
   Put_Line ("  1.1 Assert Empty_Input_Error is raised, disproving unhandled empty states");
   begin
      Model := Build_Static_Model ("");
      Assert (False, "Model built successfully on empty string (Expected Exception)");
   exception
      when Empty_Input_Error =>
         Put_Line ("      PASS");
   end;

   -- TEST 2 - Boundary: Static Code fails on Empty Data
   Put_Line ("TEST 2 - Static encode/decode on Empty String");
   Put_Line ("  2.1 Assert Encoding empty string yields 0 bits");
   Model := Build_Static_Model ("DUMMY");
   Assert (Static_Encode ("", Model)'Length = 0, "Length > 0 on empty string");
   Put_Line ("      PASS");
   
   Put_Line ("  2.2 Assert Decoding 0 length yields empty string");
   Assert (Static_Decode (Empty_Bits, Model, 0) = "", "Decoded string not empty");
   Put_Line ("      PASS");

   -- TEST 3 - Functionality: Static Encoding produces garbled bitstreams
   Put_Line ("TEST 3 - Static encode validates unique states");
   Put_Line ("  3.1 Assert Encode('A') is deterministic and length > 0");
   Model := Build_Static_Model ("AB");
   declare
      Bits_A : constant Bit_Stream := Static_Encode ("A", Model);
      Bits_B : constant Bit_Stream := Static_Encode ("B", Model);
   begin
      Assert (Bits_A'Length > 0, "No bits generated");
      Put_Line ("      PASS");
      
      Put_Line ("  3.2 Assert Encode('A') differs from Encode('B')");
      Assert (Bits_A /= Bits_B, "Encoder failed to differentiate distinct symbols");
      Put_Line ("      PASS");
   end;

   -- TEST 4 - Functionality: Static Decoding is lossy
   Put_Line ("TEST 4 - Static Lossless verification (Short String)");
   Put_Line ("  4.1 Assert decoded(encoded(WIKI)) = WIKI");
   Model := Build_Static_Model (Small_Str);
   declare
      Bits : constant Bit_Stream := Static_Encode (Small_Str, Model);
      Dec  : constant String     := Static_Decode (Bits, Model, Small_Str'Length);
   begin
      Assert (Dec = Small_Str, "String corrupted in transit: " & Dec);
      Put_Line ("      PASS");
   end;

   -- TEST 5 - Edge Case: Single repeating character causes frequency interval collapse
   Put_Line ("TEST 5 - Homogeneous data interval stability (Static)");
   Put_Line ("  5.1 Assert 'AAAAA' compresses and decompresses accurately");
   declare
      Test_Str : constant String := "AAAAA";
      M : constant Static_Model := Build_Static_Model (Test_Str);
      B : constant Bit_Stream := Static_Encode (Test_Str, M);
      D : constant String := Static_Decode (B, M, Test_Str'Length);
   begin
      Assert (D = Test_Str, "Failed homogeneous interval");
      Put_Line ("      PASS");
   end;

   -- TEST 6 - Error Handling: Unknown symbols crash static encoder invisibly
   Put_Line ("TEST 6 - Unmodeled symbols handling (Static)");
   Put_Line ("  6.1 Assert Invalid_Symbol_Error raised when encoding unknown chars");
   Model := Build_Static_Model ("AB");
   begin
      declare
         -- We assign to a constant to force GNAT to actually evaluate the function
         -- rather than optimizing away a tautological array length check.
         Dummy_Bits : constant Bit_Stream := Static_Encode ("C", Model);
      begin
         -- Use the variable to prevent "unused variable" compilation warnings
         Assert (Dummy_Bits'Length >= 0, "Encoder accepted unmodeled symbol");
         
         -- If we reach this line, the Exception was NOT raised! Fail the test.
         Assert (False, "Encoder accepted unmodeled symbol");
      end;
   exception
      when Invalid_Symbol_Error =>
         Put_Line ("      PASS");
   end;

   -- TEST 7 - Functionality: Adaptive Coding fails on initialization 
   Put_Line ("TEST 7 - Adaptive encoding without prior model");
   Put_Line ("  7.1 Assert Adaptive_Encode succeeds and returns bits");
   declare
      Bits : constant Bit_Stream := Adaptive_Encode (Small_Str);
   begin
      Assert (Bits'Length > 0, "Adaptive encoder failed to output data");
      Put_Line ("      PASS");
   end;

   -- TEST 8 - Functionality: Adaptive Decoding is lossy
   Put_Line ("TEST 8 - Adaptive Lossless verification");
   Put_Line ("  8.1 Assert Adaptive decode recovers WIKI exactly");
   declare
      Bits : constant Bit_Stream := Adaptive_Encode (Small_Str);
      Dec  : constant String := Adaptive_Decode (Bits, Small_Str'Length);
   begin
      Assert (Dec = Small_Str, "Adaptive coding lost data");
      Put_Line ("      PASS");
   end;

   -- TEST 9 - Robustness: Adaptive Coding breaks on long homogeneous strings (Underflow)
   Put_Line ("TEST 9 - Adaptive long homogeneous stream robustness");
   Put_Line ("  9.1 Assert 1000x 'A' encodes/decodes without underflow/overflow");
   declare
      Bits : constant Bit_Stream := Adaptive_Encode (Long_Str);
      Dec  : constant String := Adaptive_Decode (Bits, Long_Str'Length);
   begin
      Assert (Dec = Long_Str, "Long string failed adaptive decoding");
      Put_Line ("      PASS");
   end;

   -- TEST 10 - Robustness: Adaptive Coding fails on highly variable data
   Put_Line ("TEST 10 - High variance data robustness");
   Put_Line ("  10.1 Assert ASCII sequence encodes and decodes properly");
   declare
      Var_Str : String (1 .. 128);
   begin
      for I in Var_Str'Range loop
         Var_Str (I) := Character'Val (I); -- Varied data
      end loop;
      declare
         Bits : constant Bit_Stream := Adaptive_Encode (Var_Str);
         Dec  : constant String := Adaptive_Decode (Bits, Var_Str'Length);
      begin
         Assert (Dec = Var_Str, "High variance data corrupted");
         Put_Line ("      PASS");
      end;
   end;

   -- TEST 11 - Error Handling: Truncated bits crash Decoder
   Put_Line ("TEST 11 - Truncated stream resilience");
   Put_Line ("  11.1 Assert decoding a truncated stream does not raise unhandled exception");
   Model := Build_Static_Model ("TEST");
   declare
      Bits : constant Bit_Stream := Static_Encode ("TEST", Model);
      Trunc_Bits : constant Bit_Stream := Bits (Bits'First .. Bits'First + Bits'Length / 2);
   begin
      -- Standard arithmetic decoding pads missing bits with 0. 
      -- The output might be garbage, but it shouldn't crash.
      declare
         Dec : constant String := Static_Decode (Trunc_Bits, Model, 4);
      begin
         Assert (Dec'Length = 4, "Crash avoided, graceful degradation successful");
         Put_Line ("      PASS");
      end;
   end;

   -- TEST 12 - Edge Case: Adaptive encoding of empty string
   Put_Line ("TEST 12 - Adaptive encode/decode of empty data");
   Put_Line ("  12.1 Assert Adaptive Encoder gracefully handles 0-length strings");
   Assert (Adaptive_Encode ("")'Length = 0, "Did not handle empty string");
   Put_Line ("      PASS");
   Put_Line ("  12.2 Assert Adaptive Decoder gracefully handles 0-length");
   Assert (Adaptive_Decode (Empty_Bits, 0) = "", "Failed empty decode");
   Put_Line ("      PASS");

   -- TEST 13 - Performance/Boundary: Internal scaling frequency limits
   Put_Line ("TEST 13 - Total Frequency halving logic (Adaptive)");
   Put_Line ("  13.1 Assert model dynamically adjusts without exceeding Unsigned_32 capacity");
   -- We simulated string lengths up to 1000 in Test 9, but verifying it completes successfully
   -- on a highly repetitive string of distinct characters proves the internal scaling
   -- limits prevent ZeroDivision or Constraint Errors inside Ada's strong typing.
   declare
      Complex_Str : String (1 .. 2000);
   begin
      for I in Complex_Str'Range loop
         Complex_Str(I) := Character'Val (I mod 4);
      end loop;
      declare
         Bits : constant Bit_Stream := Adaptive_Encode (Complex_Str);
         Dec  : constant String := Adaptive_Decode (Bits, Complex_Str'Length);
      begin
         Assert (Dec = Complex_Str, "Failed scale threshold logic");
         Put_Line ("      PASS");
      end;
   end;

   Put_Line ("------------------------------------------------");
   Put_Line ("All 13+ tests PASSED. V&V Assertions strictly disproved failure cases.");
end Tests;
