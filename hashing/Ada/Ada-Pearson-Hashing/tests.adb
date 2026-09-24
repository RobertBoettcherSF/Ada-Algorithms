-- tests.adb
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Pearson_Hash; use Pearson_Hash;
with Interfaces; use Interfaces;

procedure Tests is
   -- A simple custom table for testing variability
   Custom_Table : constant Permutation_Table := (
      255, 254, 253, others => 0
   );
begin
   Put_Line("--- STARTING PEARSON HASH TESTS ---");

   -- TEST 1 - Determinism
   Put_Line("TEST 1 - Determinism (Identical inputs = identical hashes)");
   declare
      Result1 : Unsigned_8 := Pearson_Hash.Hash("Test");
      Result2 : Unsigned_8 := Pearson_Hash.Hash("Test");
   begin
      Assert(Result1 = Result2, "Determinism failed");
      Put_Line("   PASS");
   end;

   -- TEST 2 - Empty String
   Put_Line("TEST 2 - Empty String");
   Assert(Pearson_Hash.Hash("") = 0, "Empty string should return initial 0");
   Put_Line("   PASS");

   -- TEST 3 - Single Character
   Put_Line("TEST 3 - Single Character");
   Assert(Pearson_Hash.Hash("A") /= 0, "Single char hash should not be 0");
   Put_Line("   PASS");

   -- TEST 4 - Different Strings
   Put_Line("TEST 4 - Different Inputs");
   Assert(Pearson_Hash.Hash("ABC") /= Pearson_Hash.Hash("ABD"), "Different inputs yielded same hash");
   Put_Line("   PASS");

   -- TEST 5 - Variant Table Support
   Put_Line("TEST 5 - Variant Table Support");
   Assert(Pearson_Hash.Hash("Test", Default_Table) /= Pearson_Hash.Hash("Test", Custom_Table), "Different tables must produce different hashes");
   Put_Line("   PASS");

   -- TEST 6 - Binary vs String Input (Implicit Equality check)
   Put_Line("TEST 6 - Byte Array Handling");
   declare
      Bytes : Byte_Array := (65, 66, 67); -- ASCII for ABC
   begin
      Assert(Pearson_Hash.Hash(Bytes) /= 0, "Byte array hashing failed");
      Put_Line("   PASS");
   end;

   -- TEST 7 - Byte Array Determinism
   Put_Line("TEST 7 - Byte Array Determinism");
   declare
      B1 : Byte_Array := (1, 2, 3);
      B2 : Byte_Array := (1, 2, 3);
   begin
      Assert(Pearson_Hash.Hash(B1) = Pearson_Hash.Hash(B2), "Byte array consistency failed");
      Put_Line("   PASS");
   end;

   -- TEST 8 - Large Input Handling
   Put_Line("TEST 8 - Long Input");
   declare
      Long_Input : String(1..1000) := (others => 'A');
   begin
      Assert(Pearson_Hash.Hash(Long_Input) /= 0, "Long input hash failed");
      Put_Line("   PASS");
   end;

   -- TEST 9 - Boundary: Input containing Null byte
   Put_Line("TEST 9 - Null Byte Handling");
   declare
      B : Byte_Array := (0, 0, 0);
   begin
      -- 0 xor 0 = 0. Table(0) will be accessed.
      Assert(Pearson_Hash.Hash(B) /= 0, "Null byte handling failed");
      Put_Line("   PASS");
   end;

   -- TEST 10 - Case Sensitivity
   Put_Line("TEST 10 - Case Sensitivity");
   Assert(Pearson_Hash.Hash("a") /= Pearson_Hash.Hash("A"), "Hash should be case sensitive");
   Put_Line("   PASS");

   -- TEST 11 - Empty Byte Array
   Put_Line("TEST 11 - Empty Byte Array");
   declare
      B : Byte_Array(1..0);
   begin
      Assert(Pearson_Hash.Hash(B) = 0, "Empty byte array failed");
      Put_Line("   PASS");
   end;

   -- TEST 12 - Maximum Byte Values
   Put_Line("TEST 12 - Max Byte Values");
   declare
      B : Byte_Array := (255, 255);
   begin
      Assert(Pearson_Hash.Hash(B) /= 0, "Max byte range failed");
      Put_Line("   PASS");
   end;

   -- TEST 13 - Mixed Type Consistency
   Put_Line("TEST 13 - Input Type Stability");
   declare
      S : String := "ABC";
      B : Byte_Array := (65, 66, 67);
   begin
      Assert(Pearson_Hash.Hash(S) = Pearson_Hash.Hash(B), "String and Byte array logic mismatch");
      Put_Line("   PASS");
   end;

   Put_Line("--- ALL TESTS PASSED ---");
end Tests;
