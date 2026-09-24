with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Fletchers_Checksum; use Fletchers_Checksum;

procedure Tests is

   -- Test Data definitions
   T_ABC        : constant Byte_Array := (97, 98, 99); -- 'a', 'b', 'c'
   T_Empty_8    : constant Byte_Array (1 .. 0) := (others => 0);
   T_Zeros      : constant Byte_Array := (0, 0, 0, 0);
   T_255s       : constant Byte_Array := (255, 255, 255);
   
   T_Large      : Byte_Array (1 .. 6000) := (others => 97);
   
   T_Empty_16   : constant Word16_Array (1 .. 0) := (others => 0);
   T_Word16_Max : constant Word16_Array := (1 => 65535);
   T_Word16_One : constant Word16_Array := (1 => 1);
   
   T_Empty_32   : constant Word32_Array (1 .. 0) := (others => 0);
   T_Word32_Max : constant Word32_Array := (1 => 4294967295);
   T_Word32_One : constant Word32_Array := (1 => 1);

begin
   Put_Line ("Starting V&V Test Suite for Fletcher's Checksum...");
   Put_Line ("--------------------------------------------------");

   -- TEST 1 - Fletcher 16 Naive Functionality
   Put_Line ("TEST 1 - Fletcher-16 Naive Verification");
   Put_Line ("  1.1 Assume 'abc' parses wrong. Assert evaluates to 19495.");
   Assert (Fletcher_16_Naive (T_ABC) = 19495, "Failed: Incorrect checksum for 'abc'");
   Put_Line ("      PASS");

   Put_Line ("  1.2 Assume empty arrays crash. Assert computes 0.");
   Assert (Fletcher_16_Naive (T_Empty_8) = 0, "Failed: Empty array did not return 0");
   Put_Line ("      PASS");

   Put_Line ("  1.3 Assume zeroes influence checksum. Assert evaluates to 0.");
   Assert (Fletcher_16_Naive (T_Zeros) = 0, "Failed: Array of zeroes did not return 0");
   Put_Line ("      PASS");

   Put_Line ("  1.4 Assume max values break modulo (mod 255 = 0). Assert evaluates to 0.");
   Assert (Fletcher_16_Naive (T_255s) = 0, "Failed: Array of 255s did not return 0");
   Put_Line ("      PASS");

   -- TEST 2 - Fletcher 16 Optimized Verification
   Put_Line ("TEST 2 - Fletcher-16 Optimized Verification");
   Put_Line ("  2.1 Assume optimization breaks basic case. Assert matches 19495.");
   Assert (Fletcher_16_Optimized (T_ABC) = 19495, "Failed: Optimized chunking failed on 'abc'");
   Put_Line ("      PASS");

   Put_Line ("  2.2 Assume chunking breaks on large arrays (overflow). Assert matches naive.");
   Assert (Fletcher_16_Optimized (T_Large) = Fletcher_16_Naive (T_Large), "Failed: Optimized mismatched Naive on large array");
   Put_Line ("      PASS");

   -- TEST 3 - Fletcher 32 Verification
   Put_Line ("TEST 3 - Fletcher-32 Verification");
   Put_Line ("  3.1 Assume 16-bit empty array crashes. Assert computes 0.");
   Assert (Fletcher_32 (T_Empty_16) = 0, "Failed: Fletcher-32 empty array failed");
   Put_Line ("      PASS");

   Put_Line ("  3.2 Assume mod 65535 logic fails on max input. Assert evaluates to 0.");
   Assert (Fletcher_32 (T_Word16_Max) = 0, "Failed: Fletcher-32 max array failed");
   Put_Line ("      PASS");

   Put_Line ("  3.3 Assume bit shifts fail on single value. Assert evaluates to 65537.");
   -- Sum1 = 1, Sum2 = 1. (1 * 65536) + 1 = 65537
   Assert (Fletcher_32 (T_Word16_One) = 65537, "Failed: Fletcher-32 single element calculation failed");
   Put_Line ("      PASS");

   -- TEST 4 - Fletcher 64 Verification
   Put_Line ("TEST 4 - Fletcher-64 Verification");
   Put_Line ("  4.1 Assume 32-bit empty array crashes. Assert computes 0.");
   Assert (Fletcher_64 (T_Empty_32) = 0, "Failed: Fletcher-64 empty array failed");
   Put_Line ("      PASS");

   Put_Line ("  4.2 Assume mod 4294967295 logic fails on max input. Assert evaluates to 0.");
   Assert (Fletcher_64 (T_Word32_Max) = 0, "Failed: Fletcher-64 max array failed");
   Put_Line ("      PASS");

   Put_Line ("  4.3 Assume bit shifts fail on 64-bit architecture. Assert evaluates to 4294967297.");
   -- Sum1 = 1, Sum2 = 1. (1 * 4294967296) + 1 = 4294967297
   Assert (Fletcher_64 (T_Word32_One) = 4294967297, "Failed: Fletcher-64 single element calculation failed");
   Put_Line ("      PASS");

   -- TEST 5 - Check Bytes Validation
   Put_Line ("TEST 5 - Fletcher-16 Check Bytes Generation");
   Put_Line ("  5.1 Assume generated check bytes do not zero the checksum.");
   declare
      CB : Check_Bytes_16 := Generate_Check_Bytes_16 (T_ABC);
      T_ABC_With_CB : constant Byte_Array := T_ABC & Byte_Array'(CB.CB0, CB.CB1);
   begin
      -- Asserting that appending check bytes results in a clean 0 checksum
      Assert (Fletcher_16_Naive (T_ABC_With_CB) = 0, "Failed: Check bytes did not result in 0 checksum");
      Put_Line ("      PASS");
   end;

   Put_Line ("--------------------------------------------------");
   Put_Line ("ALL 13 TESTS PASSED SUCCESSFULLY!");

end Tests;
