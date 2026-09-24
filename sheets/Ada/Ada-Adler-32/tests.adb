-- tests.adb
-- Robust Test Suite fulfilling Verification & Validation requirements
with Ada.Text_IO; use Ada.Text_IO;
with Interfaces; use Interfaces;
with Adler32; use Adler32;

procedure Tests is
   -- Assertion wrapper handling V&V formatting
   procedure Assert (Condition : Boolean; Assumption_Disproved : String) is
   begin
      if not Condition then
         Put_Line ("      [FAIL] Failed to disprove: " & Assumption_Disproved);
         raise Program_Error with "Test suite failed.";
      else
         Put_Line ("      [PASS] DISPROVED: " & Assumption_Disproved);
      end if;
   end Assert;

   Empty_Arr       : Byte_Array (1 .. 0);
   Wiki_Str        : constant String := "Wikipedia";
   Wiki_Bytes      : Byte_Array := To_Byte_Array (Wiki_Str);
   Wiki_Expected   : constant Checksum := 16#11E60398#; 
   Single_Char     : Byte_Array := To_Byte_Array ("A");
   Zero_Arr        : Byte_Array (1 .. 1) := (1 => 0);
   
   -- Large array generation for boundaries
   Block_Boundary  : Byte_Array (1 .. 5552) := (others => 97); -- 'a'
   Overflow_Block  : Byte_Array (1 .. 10000) := (others => 120); -- 'x'
   Offset_Bounds   : Byte_Array (5 .. 10) := (others => 66); -- 'B'

begin
   Put_Line ("=================================================");
   Put_Line ("  Adler-32 V&V Test Suite");
   Put_Line ("  Goal: Disprove failure assumptions (Broken-Code Bias)");
   Put_Line ("=================================================");

   Put_Line ("TEST 1 - Handling Empty Inputs (Basic)");
   Assert (Calculate_Basic (Empty_Arr) = 1, "Basic fails on empty arrays");
   Assert (Calculate_Basic (To_Byte_Array("")) = 1, "To_Byte_Array creates invalid empty arrays");

   Put_Line ("TEST 2 - Handling Empty Inputs (Optimized)");
   Assert (Calculate_Optimized (Empty_Arr) = 1, "Optimized fails on empty arrays");

   Put_Line ("TEST 3 - Reference Verification (Wikipedia Example Basic)");
   Assert (Calculate_Basic (Wiki_Bytes) = Wiki_Expected, "Basic math calculates Wikipedia string incorrectly");

   Put_Line ("TEST 4 - Reference Verification (Wikipedia Example Optimized)");
   Assert (Calculate_Optimized (Wiki_Bytes) = Wiki_Expected, "Optimized math deviates from standard spec");

   Put_Line ("TEST 5 - Single Byte Calculation (Basic)");
   Assert (Calculate_Basic (Single_Char) = 16#00420042#, "Basic math fails on n=1 strings");

   Put_Line ("TEST 6 - Single Byte Calculation (Optimized)");
   Assert (Calculate_Optimized (Single_Char) = 16#00420042#, "Optimized math fails on n=1 strings");

   Put_Line ("TEST 7 - Minimum State Growth");
   Assert (Calculate_Basic (Zero_Arr) = 65537, "Null bytes corrupt state variables (A, B)");
   Assert (Calculate_Optimized (Zero_Arr) = 65537, "Optimized fails with null bytes");

   Put_Line ("TEST 8 - Array Indexing Robustness");
   -- Test an array that does not start at index 1 to ensure 'Range and 'First are used
   Assert (Calculate_Basic (Offset_Bounds) = Calculate_Optimized (Offset_Bounds), 
      "Algorithm assumes arrays always start at index 1");

   Put_Line ("TEST 9 - Block Boundary Threshold (5552 bytes)");
   -- Exactly at the boundary where modulo is evaluated in Optimized
   Assert (Calculate_Basic (Block_Boundary) = Calculate_Optimized (Block_Boundary), 
      "Optimized fails when matching block limit exactly");

   Put_Line ("TEST 10 - Exceeding Block Boundary (>5552 bytes)");
   -- Forces the `Remaining > 0` outer loop to iterate multiple times
   Assert (Calculate_Basic (Overflow_Block) = Calculate_Optimized (Overflow_Block), 
      "Optimized fails and drops bytes across multiple chunk boundaries");

   Put_Line ("TEST 11 - Conversion Edge Case");
   Assert (To_Byte_Array("A")(1) = 65, "ASCII-to-Byte Conversion incorrectly shifts values");

   Put_Line ("TEST 12 - Symmetric Transitivity");
   Assert (Calculate_Basic(Wiki_Bytes) = Calculate_Optimized(Wiki_Bytes), 
      "Basic and Optimized yield divergent results for standard ascii data");

   Put_Line ("TEST 13 - Maximum Values Edge Case");
   declare
      Max_Bytes : Byte_Array (1 .. 100) := (others => 255);
   begin
      Assert (Calculate_Basic (Max_Bytes) = Calculate_Optimized (Max_Bytes), 
         "Unsigned_8 maximum value (255) triggers mathematical overflow");
   end;

   Put_Line ("=================================================");
   Put_Line ("  ALL 13 TESTS PASSED. Assumptions disproved.");
   Put_Line ("=================================================");
end Tests;
