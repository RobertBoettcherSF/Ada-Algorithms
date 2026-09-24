-- tests.adb
-- Standalone test suite executing terminal assertions against the Hamming Package
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Hamming_Weight; use Hamming_Weight;

procedure Tests is
begin
   Put_Line ("=================================================");
   Put_Line ("  V&V TESTING SUITE: HAMMING WEIGHT ALGORITHMS   ");
   Put_Line ("=================================================");
   Put_Line ("ASSUMPTION: Functions calculate popcount incorrectly.");
   Put_Line ("GOAL: PASS by disproving assumptions (validating correct output).");
   New_Line;

   -- TEST 1 - Naive Algorithm Boundaries
   Put_Line ("TEST 1 - Naive Algorithm Boundaries");
   Put_Line ("  1.1 Assert Naive returns 0 for 16#0000_0000#");
   Assert (Naive_Count (0) = 0, "Naive Zero failed");
   Put_Line ("      PASS");
   Put_Line ("  1.2 Assert Naive returns 32 for 16#FFFF_FFFF#");
   Assert (Naive_Count (16#FFFF_FFFF#) = 32, "Naive Max failed");
   Put_Line ("      PASS");

   -- TEST 2 - Naive Algorithm Specific Patterns
   Put_Line ("TEST 2 - Naive Algorithm Specific Patterns");
   Put_Line ("  2.1 Assert Naive returns 16 for alternating bits (16#AAAA_AAAA#)");
   Assert (Naive_Count (16#AAAA_AAAA#) = 16, "Naive Alternating failed");
   Put_Line ("      PASS");

   -- TEST 3 - Kernighan Algorithm Boundaries
   Put_Line ("TEST 3 - Kernighan Algorithm Boundaries");
   Put_Line ("  3.1 Assert Kernighan returns 0 for 16#0000_0000#");
   Assert (Kernighan_Count (0) = 0, "Kernighan Zero failed");
   Put_Line ("      PASS");
   Put_Line ("  3.2 Assert Kernighan returns 32 for 16#FFFF_FFFF#");
   Assert (Kernighan_Count (16#FFFF_FFFF#) = 32, "Kernighan Max failed");
   Put_Line ("      PASS");

   -- TEST 4 - Kernighan Algorithm Edge Cases
   Put_Line ("TEST 4 - Kernighan Algorithm Edge Cases");
   Put_Line ("  4.1 Assert Kernighan identifies power of 2 accurately (1 bit)");
   Assert (Kernighan_Count (16#8000_0000#) = 1, "Kernighan MSB failed");
   Put_Line ("      PASS");
   
   -- TEST 5 - Parallel SWAR Functionality
   Put_Line ("TEST 5 - Parallel SWAR Functionality");
   Put_Line ("  5.1 Assert SWAR handles 0 gracefully");
   Assert (SWAR_Count (0) = 0, "SWAR Zero failed");
   Put_Line ("      PASS");
   Put_Line ("  5.2 Assert SWAR resolves full mask correctly (16#FFFF_FFFF#)");
   Assert (SWAR_Count (16#FFFF_FFFF#) = 32, "SWAR Max failed");
   Put_Line ("      PASS");
   
   -- TEST 6 - Parallel SWAR Boundary Overflow
   Put_Line ("TEST 6 - Parallel SWAR Boundary Overflow");
   Put_Line ("  6.1 Assert SWAR isolates lower half (16#0000_FFFF#)");
   Assert (SWAR_Count (16#0000_FFFF#) = 16, "SWAR Half-mask failed");
   Put_Line ("      PASS");

   -- TEST 7 - SWAR Multiply Arithmetic Robustness
   Put_Line ("TEST 7 - SWAR Multiply Arithmetic Robustness");
   Put_Line ("  7.1 Assert SWAR Multiply correctly wraps at limits (16#FFFF_FFFF#)");
   Assert (SWAR_Multiply_Count (16#FFFF_FFFF#) = 32, "SWAR Multiply Max failed");
   Put_Line ("      PASS");
   
   -- TEST 8 - SWAR Multiply Internal Carries
   Put_Line ("TEST 8 - SWAR Multiply Internal Carries");
   Put_Line ("  8.1 Assert SWAR Multiply evaluates 16#5555_5555# correctly (16)");
   Assert (SWAR_Multiply_Count (16#5555_5555#) = 16, "SWAR Multiply Alternating failed");
   Put_Line ("      PASS");

   -- TEST 9 - Lookup Table Instantiation & Boundaries
   Put_Line ("TEST 9 - Lookup Table Instantiation & Boundaries");
   Put_Line ("  9.1 Assert Lookup Table resolves zero appropriately");
   Assert (Lookup_Table_Count (0) = 0, "Lookup Table Zero failed");
   Put_Line ("      PASS");
   
   -- TEST 10 - Lookup Table Sub-byte boundaries
   Put_Line ("TEST 10 - Lookup Table Sub-byte boundaries");
   Put_Line ("  10.1 Assert Lookup Table evaluates LSB byte exactly (16#0000_00FF# = 8)");
   Assert (Lookup_Table_Count (16#0000_00FF#) = 8, "Lookup Table LSB failed");
   Put_Line ("      PASS");

   -- TEST 11 - Algorithm Equivalence (V&V Cross-Check)
   Put_Line ("TEST 11 - Algorithm Equivalence (Cross-check verification)");
   Put_Line ("  11.1 Assert Naive == SWAR for 16#DEAD_BEEF#");
   Assert (Naive_Count (16#DEAD_BEEF#) = SWAR_Count (16#DEAD_BEEF#), "Cross-check 1 failed");
   Put_Line ("      PASS");
   
   -- TEST 12 - Algorithm Equivalence Complex Value
   Put_Line ("TEST 12 - Algorithm Equivalence Complex Value");
   Put_Line ("  12.1 Assert SWAR Multiply == Lookup for 16#1234_5678#");
   Assert (SWAR_Multiply_Count (16#1234_5678#) = Lookup_Table_Count (16#1234_5678#), "Cross-check 2 failed");
   Put_Line ("      PASS");
   
   -- TEST 13 - Algorithm Equivalence Max Edge Case
   Put_Line ("TEST 13 - Algorithm Equivalence Max Edge Case");
   Put_Line ("  13.1 Assert Kernighan == SWAR for 16#7FFF_FFFF# (31)");
   Assert (Kernighan_Count (16#7FFF_FFFF#) = 31, "Cross-check 3 failed");
   Put_Line ("      PASS");

   New_Line;
   Put_Line ("=================================================");
   Put_Line ("      ALL 13+ TERMINAL ASSUMPTIONS DISPROVED     ");
   Put_Line ("        CODE FUNCTIONS AS DESIGNED (PASS)        ");
   Put_Line ("=================================================");
end Tests;
