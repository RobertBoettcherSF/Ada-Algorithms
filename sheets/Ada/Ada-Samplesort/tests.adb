-- tests.adb
-- Validation and Verification test suite assuming the code is broken.

with Ada.Text_IO; use Ada.Text_IO;
with Sample_Sort; use Sample_Sort;

procedure Tests is

   -- Helper procedure for assertions
   procedure Assert (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Put_Line ("      FAIL: " & Message);
         raise Program_Error with Message;
      else
         Put_Line ("      PASS");
      end if;
   end Assert;

   -- Helper to check if array is sorted
   function Is_Sorted (Arr : Data_Array) return Boolean is
   begin
      for I in Arr'First .. Arr'Last - 1 loop
         if Arr(I) > Arr(I + 1) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Sorted;

   Empty_Arr : Data_Array (1 .. 0);
   Single    : Data_Array := (1 => 42);
   Sorted    : Data_Array := (1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
   Reverse_A : Data_Array := (10, 9, 8, 7, 6, 5, 4, 3, 2, 1);
   Identical : Data_Array := (5, 5, 5, 5, 5, 5, 5, 5, 5, 5);
   Random_1  : Data_Array := (14, 2, 33, 9, 100, 4, 18, 1, 90, 50, 11, 7, 23);
   Random_2  : Data_Array := (14, 2, 33, 9, 100, 4, 18, 1, 90, 50, 11, 7, 23);
   Random_3  : Data_Array := (14, 2, 33, 9, 100, 4, 18, 1, 90, 50, 11, 7, 23);
   
   Large_Arr : Data_Array (1 .. 1000);

begin
   Put_Line ("===============================================");
   Put_Line (" SAMPLESORT V&V TEST SUITE (15 ASSUMPTIONS)    ");
   Put_Line ("===============================================");

   -- TEST 1
   Put_Line ("TEST 1 - Sequential: Null Array Handling");
   Put_Line ("  1.1 [Assertion: Assume code crashes on empty array]");
   Sequential_Sample_Sort (Empty_Arr, 3);
   Assert (Is_Sorted (Empty_Arr), "Empty array caused crash or modification");

   -- TEST 2
   Put_Line ("TEST 2 - Sequential: Single Element Array");
   Put_Line ("  2.1 [Assertion: Assume single element bounds are corrupted]");
   Sequential_Sample_Sort (Single, 2);
   Assert (Is_Sorted (Single) and Single(1) = 42, "Single element corrupted");

   -- TEST 3
   Put_Line ("TEST 3 - Sequential: Already Sorted Data");
   Put_Line ("  3.1 [Assertion: Assume pre-sorted data causes misordering]");
   Sequential_Sample_Sort (Sorted, 3);
   Assert (Is_Sorted (Sorted), "Sorted array was broken");

   -- TEST 4
   Put_Line ("TEST 4 - Sequential: Reverse Sorted Data");
   Put_Line ("  4.1 [Assertion: Assume reverse sorted data fails to sort]");
   Sequential_Sample_Sort (Reverse_A, 3);
   Assert (Is_Sorted (Reverse_A), "Reverse array not sorted");

   -- TEST 5
   Put_Line ("TEST 5 - Sequential: Identical Elements");
   Put_Line ("  5.1 [Assertion: Assume identical elements cause O(N^2) infinite loops]");
   Sequential_Sample_Sort (Identical, 3);
   Assert (Is_Sorted (Identical), "Identical array failed");

   -- TEST 6
   Put_Line ("TEST 6 - Sequential: Random Unsorted Array");
   Put_Line ("  6.1 [Assertion: Assume generic sequential samplesort fails to order random data]");
   Sequential_Sample_Sort (Random_1, 3);
   Assert (Is_Sorted (Random_1), "Random array 1 failed to sort");

   -- TEST 7
   Put_Line ("TEST 7 - Parallel: Empty Array Tasks");
   Put_Line ("  7.1 [Assertion: Assume parallel task dispatch crashes on 0 elements]");
   Parallel_Sample_Sort (Empty_Arr, 4);
   Assert (Is_Sorted (Empty_Arr), "Parallel empty array failed");

   -- TEST 8
   Put_Line ("TEST 8 - Parallel: Random Unsorted Array");
   Put_Line ("  8.1 [Assertion: Assume shared memory data race corrupts sort]");
   Parallel_Sample_Sort (Random_2, 4);
   Assert (Is_Sorted (Random_2), "Parallel random array failed");

   -- TEST 9
   Put_Line ("TEST 9 - Parallel: Buckets > Elements");
   Put_Line ("  9.1 [Assertion: Assume algorithm crashes when buckets exceed array length]");
   Parallel_Sample_Sort (Single, 10);
   Assert (Is_Sorted (Single), "Oversized buckets failed");

   -- TEST 10
   Put_Line ("TEST 10 - Oversampling: Random Unsorted Array");
   Put_Line ("  10.1 [Assertion: Assume oversampling formula breaks sort logic]");
   Oversampling_Sample_Sort (Random_3, 3, 2);
   Assert (Is_Sorted (Random_3), "Oversampled array failed to sort");

   -- TEST 11
   Put_Line ("TEST 11 - Exception Handling: 0 Buckets");
   Put_Line ("  11.1 [Assertion: Assume 0 buckets allows Division by Zero instead of exception]");
   begin
      Sequential_Sample_Sort (Random_1, 0);
      Assert (False, "Did not raise Invalid_Bucket_Count");
   exception
      when Invalid_Bucket_Count =>
         Assert (True, "Raised Invalid_Bucket_Count");
   end;

   -- TEST 12
   Put_Line ("TEST 12 - Exception Handling: Invalid Oversampling Factor");
   Put_Line ("  12.1 [Assertion: Assume factor of 0 corrupts memory quietly]");
   begin
      Oversampling_Sample_Sort (Random_1, 3, 0);
      Assert (False, "Did not raise Invalid_Oversample_Factor");
   exception
      when Invalid_Oversample_Factor =>
         Assert (True, "Raised Invalid_Oversample_Factor");
   end;
   
   -- TEST 13
   Put_Line ("TEST 13 - Stress Test: Large Sequential Sort");
   Put_Line ("  13.1 [Assertion: Assume 1000 items causes stack overflow / fails]");
   for I in Large_Arr'Range loop
      Large_Arr(I) := Data_Element(1000 - I); -- Reverse sorted
   end loop;
   Sequential_Sample_Sort (Large_Arr, 10);
   Assert (Is_Sorted (Large_Arr), "Large Sequential Sort failed");

   -- TEST 14
   Put_Line ("TEST 14 - Stress Test: Large Parallel Sort");
   Put_Line ("  14.1 [Assertion: Assume task spawning limits out on 1000 items / fails]");
   for I in Large_Arr'Range loop
      Large_Arr(I) := Data_Element((I * 73) mod 1000); -- Pseudo-random
   end loop;
   Parallel_Sample_Sort (Large_Arr, 8);
   Assert (Is_Sorted (Large_Arr), "Large Parallel Sort failed");
   
   -- TEST 15
   Put_Line ("TEST 15 - Helper Fallback: Base Quicksort Validation");
   Put_Line ("  15.1 [Assertion: Assume underlying fallback quicksort is broken]");
   for I in Large_Arr'Range loop
      Large_Arr(I) := Data_Element((I * 37) mod 100);
   end loop;
   Quick_Sort (Large_Arr);
   Assert (Is_Sorted (Large_Arr), "Base Quicksort failed");

   Put_Line ("===============================================");
   Put_Line (" ALL 15 ASSUMPTIONS DISPROVEN - SYSTEM SECURE  ");
   Put_Line ("===============================================");

end Tests;
