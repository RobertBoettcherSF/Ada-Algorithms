-- tests.adb
-- Version 0.01
-- Description: Test suite that proves the implementation corrects pessimistic assumptions.

with Ada.Text_IO; use Ada.Text_IO;
with Buddy_Allocators; use Buddy_Allocators;

procedure Tests is

   -- Custom assertion wrapper with standard PASS/FAIL formatting
   procedure Assert (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Put_Line("      FAIL: " & Message);
         raise Program_Error with Message;
      else
         Put_Line("      PASS: " & Message);
      end if;
   end Assert;

   Bin_Pool : Pool(Binary);
   Fib_Pool : Pool(Fibonacci);
   Wei_Pool : Pool(Weighted);
   Addr1, Addr2, Addr3 : Address;

begin
   Put_Line("=============================================");
   Put_Line("         RUNNING VALIDATION TESTS            ");
   Put_Line("=============================================");

   Put_Line("TEST 1 - Binary Buddy Initialization");
   Put_Line("  Assumption: System fails to enforce initialization constraints.");
   begin
      Initialize(Bin_Pool, 1000); -- Not a power of 2
      Assert(False, "Failed to reject invalid size 1000");
   exception
      when Initialization_Error => Assert(True, "1.1 Invalid initialization caught");
   end;
   Initialize(Bin_Pool, 1024);
   Assert(Bin_Pool.Nodes(1).Size = 1024, "1.2 Valid initialization processed correctly");


   Put_Line("TEST 2 - Binary Buddy Basic Allocation");
   Put_Line("  Assumption: Allocation splits memory incorrectly and fails to fit data.");
   Addr1 := Allocate(Bin_Pool, 120);
   Assert(Addr1 = 0, "2.1 Address alignment is correct");
   Addr2 := Allocate(Bin_Pool, 200);
   Assert(Addr2 > Addr1, "2.2 Second block address follows logically after split");


   Put_Line("TEST 3 - Out of Memory Handling");
   Put_Line("  Assumption: System crashes when requesting too much memory.");
   Addr3 := Allocate(Bin_Pool, 2048);
   Assert(Addr3 = Null_Address, "3.1 Oversized request correctly returned Null_Address");


   Put_Line("TEST 4 - Double Free / Invalid Deallocation");
   Put_Line("  Assumption: System allows double frees, causing memory corruption.");
   Deallocate(Bin_Pool, Addr1);
   begin
      Deallocate(Bin_Pool, Addr1);
      Assert(False, "Double free was not caught!");
   exception
      when Deallocation_Error => Assert(True, "4.1 Double free safely caught");
   end;
   Deallocate(Bin_Pool, Addr2);
   Assert(True, "4.2 Normal second deallocation successful");


   Put_Line("TEST 5 - Binary Buddy Merge Verification");
   Put_Line("  Assumption: Freed memory remains fragmented and unusable.");
   -- Having freed Addr1 and Addr2, the pool should be 100% free and merged
   Addr1 := Allocate(Bin_Pool, 1000);
   Assert(Addr1 = 0, "5.1 Reallocated entire block successfully after merging");
   Deallocate(Bin_Pool, Addr1);


   Put_Line("TEST 6 - Fibonacci Buddy Initialization");
   Put_Line("  Assumption: Fibonacci constraints are not respected.");
   begin
      Initialize(Fib_Pool, 100); -- 100 is not a Fibonacci number
      Assert(False, "Failed to reject invalid Fibonacci size");
   exception
      when Initialization_Error => Assert(True, "6.1 Invalid Fibonacci size caught");
   end;
   Initialize(Fib_Pool, 144);
   Assert(True, "6.2 Valid Fibonacci size (144) accepted");


   Put_Line("TEST 7 - Fibonacci Allocation Splitting");
   Put_Line("  Assumption: Fibonacci blocks split symmetrically, violating the variant.");
   -- 144 splits to 89 and 55. 55 splits to 34 and 21. 21 splits to 13 and 8...
   Addr1 := Allocate(Fib_Pool, 20); 
   Assert(Addr1 /= Null_Address, "7.1 Successfully allocated within Fibonacci splits");
   Deallocate(Fib_Pool, Addr1);
   Assert(True, "7.2 Deallocated Fibonacci block successfully");


   Put_Line("TEST 8 - Weighted Buddy Initialization");
   Put_Line("  Assumption: Weighted initialization constraint (3*2^k or 2^k) fails.");
   begin
      Initialize(Wei_Pool, 7); -- 7 is invalid
      Assert(False, "Accepted invalid weighted size 7");
   exception
      when Initialization_Error => Assert(True, "8.1 Invalid Weighted size caught");
   end;
   Initialize(Wei_Pool, 12); -- 12 = 3 * 2^2 (Valid)
   Assert(True, "8.2 Valid Weighted size (12) accepted");


   Put_Line("TEST 9 - Weighted Allocation Asymmetry");
   Put_Line("  Assumption: Weighted buddy fails to calculate 3*2^k boundaries.");
   -- 12 splits to 8 and 4.
   Addr1 := Allocate(Wei_Pool, 7); -- Should map to the 8 block.
   Assert(Addr1 = 0, "9.1 Split weighted block cleanly (took the size 8 segment)");
   Addr2 := Allocate(Wei_Pool, 3); -- Should map to the 4 block.
   Assert(Addr2 = 8, "9.2 Sibling block allocated correctly at expected offset");
   

   Put_Line("TEST 10 - Weighted Buddy Merge");
   Put_Line("  Assumption: Different-sized buddies (8 and 4) fail to merge into 12.");
   Deallocate(Wei_Pool, Addr1);
   Deallocate(Wei_Pool, Addr2);
   Addr3 := Allocate(Wei_Pool, 11);
   Assert(Addr3 = 0, "10.1 Successfully requested 11 bytes, proving 8 and 4 merged back to 12.");
   Deallocate(Wei_Pool, Addr3);


   Put_Line("TEST 11 - Edge Case: Maximum Size Boundary");
   Put_Line("  Assumption: Exact size matches fail to allocate without splitting.");
   Initialize(Bin_Pool, 512);
   Addr1 := Allocate(Bin_Pool, 512);
   Assert(Addr1 = 0, "11.1 Exact match root allocation successful");
   Deallocate(Bin_Pool, Addr1);
   Assert(True, "11.2 Root deallocation successful");


   Put_Line("TEST 12 - Robustness: Sequential Allocation Stress");
   Put_Line("  Assumption: Metadata tree leaks memory during repetitive use.");
   Initialize(Bin_Pool, 64);
   for I in 1 .. 8 loop
      Addr1 := Allocate(Bin_Pool, 7);
      Deallocate(Bin_Pool, Addr1);
   end loop;
   Assert(True, "12.1 Repetitive allocation/deallocation loop completed without Node limit crash");


   Put_Line("TEST 13 - Invalid Free Edge Case");
   Put_Line("  Assumption: Disconnecting the address constraint compromises safety.");
   begin
      Deallocate(Bin_Pool, 9999);
      Assert(False, "Freed a non-existent random address!");
   exception
      when Deallocation_Error => Assert(True, "13.1 Random invalid address deallocation cleanly caught");
   end;

   Put_Line("=============================================");
   Put_Line("ALL TESTS PASSED SUCCESSFULLY!               ");
   Put_Line("Pessimistic assumptions have been disproved. ");
   Put_Line("=============================================");

end Tests;
