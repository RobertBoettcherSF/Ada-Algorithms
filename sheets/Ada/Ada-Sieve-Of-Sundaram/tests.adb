-- Test Suite
-- Testing Philosophy: Assume broken code, test 13+ boundaries, edges, and logic cores. 
-- A 'PASS' dictates the assumption is false and the implementation met V&V constraints.

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Sieve_Of_Sundaram; use Sieve_Of_Sundaram;

procedure Tests is
   Primes_To_10 : constant Prime_Array (1 .. 4) := (2, 3, 5, 7);
begin
   Put_Line ("Starting V&V Test Suite for Sieve of Sundaram...");
   Put_Line ("------------------------------------------------");

   -- TEST 1 - Edge Case: Below absolute minimum bounds
   Put_Line ("TEST 1 - Limit below first prime (1)");
   Put_Line ("  1.1 Assert Standard_Sundaram(1) is empty");
   Assert (Standard_Sundaram(1)'Length = 0, "Failed: Length should be 0");
   Put_Line ("      PASS");

   -- TEST 2 - Edge Case: Exactly at first prime (which circumvents the 'odd' formula)
   Put_Line ("TEST 2 - Limit exactly at first prime (2)");
   Put_Line ("  2.1 Assert Standard_Sundaram(2) returns [2]");
   declare
      Res : constant Prime_Array := Standard_Sundaram(2);
   begin
      Assert (Res'Length = 1 and then Res(1) = 2, "Failed: Should be [2]");
      Put_Line ("      PASS");
   end;

   -- TEST 3 - Functional Verification: Known sequential baseline
   Put_Line ("TEST 3 - Limit up to 10");
   Put_Line ("  3.1 Assert Standard_Sundaram(10) yields [2, 3, 5, 7]");
   Assert (Standard_Sundaram(10) = Primes_To_10, "Failed: Primes up to 10 are incorrect");
   Put_Line ("      PASS");

   -- TEST 4 - Error Handling: Impossible Boundaries
   Put_Line ("TEST 4 - Negative Limit");
   Put_Line ("  4.1 Assert Standard_Sundaram(-5) silently traps to empty array");
   Assert (Standard_Sundaram(-5)'Length = 0, "Failed: Negative limit should return empty");
   Put_Line ("      PASS");

   -- TEST 5 - Variant Verification: Count-Only implementation to 100
   Put_Line ("TEST 5 - Count_Primes_Sundaram to 100");
   Put_Line ("  5.1 Assert Count(100) = 25 (Universal truth)");
   Assert (Count_Primes_Sundaram(100) = 25, "Failed: Count to 100 should be 25");
   Put_Line ("      PASS");

   -- TEST 6 - Variant Verification: Performance scale boundary
   Put_Line ("TEST 6 - Count_Primes_Sundaram to 1000");
   Put_Line ("  6.1 Assert Count(1000) = 168");
   Assert (Count_Primes_Sundaram(1000) = 168, "Failed: Count to 1000 should be 168");
   Put_Line ("      PASS");

   -- TEST 7 - Variant Verification: Count edge case correlation
   Put_Line ("TEST 7 - Count_Primes_Sundaram edge case correlation");
   Put_Line ("  7.1 Assert Count(1) = 0");
   Assert (Count_Primes_Sundaram(1) = 0, "Failed: Count(1) should be 0");
   Put_Line ("      PASS");

   -- TEST 8 - Logical Independence: Sundaram formula primality check (Valid)
   Put_Line ("TEST 8 - Is_Prime_Sundaram for valid large prime");
   Put_Line ("  8.1 Assert Is_Prime_Sundaram(7919) is True (1000th prime)");
   Assert (Is_Prime_Sundaram(7919), "Failed: 7919 must compute as prime");
   Put_Line ("      PASS");

   -- TEST 9 - Logical Independence: Sundaram formula primality check (Odd Composite)
   Put_Line ("TEST 9 - Is_Prime_Sundaram for odd composite");
   Put_Line ("  9.1 Assert Is_Prime_Sundaram(9) is False");
   Assert (not Is_Prime_Sundaram(9), "Failed: 9 is odd but not prime");
   Put_Line ("      PASS");

   -- TEST 10 - Logical Independence: Sub-zero primality testing
   Put_Line ("TEST 10 - Is_Prime_Sundaram for sub-zero range");
   Put_Line ("  10.1 Assert Is_Prime_Sundaram(-17) is False");
   Assert (not Is_Prime_Sundaram(-17), "Failed: negative numbers are not processed as primes");
   Put_Line ("      PASS");

   -- TEST 11 - State Consistency: Variant output matching
   Put_Line ("TEST 11 - Consistency between Standard and Count algorithms");
   Put_Line ("  11.1 Assert Standard_Sundaram(500)'Length = Count(500)");
   Assert (Standard_Sundaram(500)'Length = Count_Primes_Sundaram(500), "Failed: Mismatched dimensions");
   Put_Line ("      PASS");

   -- TEST 12 - Algorithm Evasion Check: Even composites
   Put_Line ("TEST 12 - Even number prime check (Circumventing main loops)");
   Put_Line ("  12.1 Assert Is_Prime_Sundaram(10) is False");
   Assert (not Is_Prime_Sundaram(10), "Failed: 10 is even composite");
   Put_Line ("      PASS");

   -- TEST 13 - Boundary Inclusivity: Is the max limit included if prime?
   Put_Line ("TEST 13 - Array bounds exact match limits");
   Put_Line ("  13.1 Assert Standard_Sundaram(11) includes 11");
   declare
      Res : constant Prime_Array := Standard_Sundaram(11);
   begin
      Assert (Res(Res'Last) = 11, "Failed: Array did not include bounding prime");
      Put_Line ("      PASS");
   end;
   
   Put_Line ("------------------------------------------------");
   Put_Line ("All assumptions disproven. 13/13 V&V Tests PASS.");
end Tests;
