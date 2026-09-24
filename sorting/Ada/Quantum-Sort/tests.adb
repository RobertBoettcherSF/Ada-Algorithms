with Ada.Text_IO; use Ada.Text_IO;
with Quantum_Sort; use Quantum_Sort;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS — " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL — " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;
begin
   -- TEST 1 — Empty Array Verification
   Put_Line ("TEST 1 — Empty Array Verification");
   declare
      Empty_Arr : Element_Array (1 .. 0);
      Test_Arr  : Element_Array (1 .. 0);
   begin
      Check ("1.1 Empty array is recognized as sorted", Is_Sorted (Empty_Arr));
      Sort_Comparison (Test_Arr);
      Check ("1.2 Comparison sort handles empty array", Test_Arr'Length = 0);
      Sort_Parallel_Network (Test_Arr);
      Check ("1.3 Parallel network sort handles empty array", Test_Arr'Length = 0);
   end;

   -- TEST 2 — Single Element Array
   Put_Line ("TEST 2 — Single Element Array");
   declare
      Single_Arr : constant Element_Array := [1 => 42];
   begin
      Check ("2.1 Single element array is sorted", Is_Sorted (Single_Arr));
      declare
         Mutable_Arr : Element_Array := Single_Arr;
      begin
         Sort_Frequency (Mutable_Arr);
         Check ("2.2 Frequency sort preserves single element", Mutable_Arr (1) = 42);
         Sort_Space_Bounded (Mutable_Arr);
         Check ("2.3 Space bounded sort preserves single element", Mutable_Arr (1) = 42);
      end;
   end;

   -- TEST 3 — Comparison Sort with Unsorted Data
   Put_Line ("TEST 3 — Comparison Sort with Unsorted Data");
   declare
      Arr : Element_Array := [5, 2, 9, 1, 7];
   begin
      Check ("3.1 Array is initially unsorted", not Is_Sorted (Arr));
      Sort_Comparison (Arr);
      Check ("3.2 Array is sorted after Sort_Comparison", Is_Sorted (Arr));
      Check ("3.3 Elements correctly ordered (first is min)", Arr (Arr'First) = 1);
   end;

   -- TEST 4 — Parallel Network Sort with Unsorted Data
   Put_Line ("TEST 4 — Parallel Network Sort with Unsorted Data");
   declare
      Arr : Element_Array := [20, 15, 10, 5, 0, -5];
   begin
      Check ("4.1 Array is initially unsorted", not Is_Sorted (Arr));
      Sort_Parallel_Network (Arr);
      Check ("4.2 Array is sorted after Sort_Parallel_Network", Is_Sorted (Arr));
      Check ("4.3 Elements correctly ordered (last is max)", Arr (Arr'Last) = 20);
   end;

   -- TEST 5 — Frequency Sort with Unsorted Data
   Put_Line ("TEST 5 — Frequency Sort with Unsorted Data");
   declare
      Arr : Element_Array := [3, 1, 4, 1, 5, 9, 2, 6];
   begin
      Check ("5.1 Array is initially unsorted", not Is_Sorted (Arr));
      Sort_Frequency (Arr);
      Check ("5.2 Array is sorted after Sort_Frequency", Is_Sorted (Arr));
      Check ("5.3 Minimum element at start", Arr (Arr'First) = 1);
   end;

   -- TEST 6 — Space Bounded Sort with Unsorted Data
   Put_Line ("TEST 6 — Space Bounded Sort with Unsorted Data");
   declare
      Arr : Element_Array := [8, 3, 5, 1, 9, 6];
   begin
      Check ("6.1 Array is initially unsorted", not Is_Sorted (Arr));
      Sort_Space_Bounded (Arr);
      Check ("6.2 Array is sorted after Sort_Space_Bounded", Is_Sorted (Arr));
      Check ("6.3 Maximum element at end", Arr (Arr'Last) = 9);
   end;

   -- TEST 7 — Duplicate Elements Handling across Variants
   Put_Line ("TEST 7 — Duplicate Elements Handling");
   declare
      Arr1 : Element_Array := [4, 2, 4, 1, 2, 1];
      Arr2 : Element_Array := [4, 2, 4, 1, 2, 1];
   begin
      Sort_Comparison (Arr1);
      Sort_Frequency (Arr2);
      Check ("7.1 Comparison sort handles duplicates correctly", Is_Sorted (Arr1));
      Check ("7.2 Frequency sort handles duplicates correctly", Is_Sorted (Arr2));
      Check ("7.3 Both methods produce identical sorted results", Arr1 = Arr2);
   end;

   -- TEST 8 — Negative Numbers Sorting
   Put_Line ("TEST 8 — Negative Numbers Sorting");
   declare
      Arr : Element_Array := [-3, 15, -10, 0, 8, -5];
   begin
      Sort_Parallel_Network (Arr);
      Check ("8.1 Parallel network handles negative numbers", Is_Sorted (Arr));
      Check ("8.2 Most negative element is first", Arr (Arr'First) = -10);
      Check ("8.3 Most positive element is last", Arr (Arr'Last) = 15);
   end;

   -- TEST 9 — Already Sorted Array Invariant
   Put_Line ("TEST 9 — Already Sorted Array Invariant");
   declare
      Arr : Element_Array := [1, 2, 3, 4, 5, 6];
   begin
      Check ("9.1 Array is recognized as already sorted", Is_Sorted (Arr));
      Sort_Comparison (Arr);
      Check ("9.2 Sorted array remains sorted after Comparison Sort", Is_Sorted (Arr));
      Check ("9.3 Elements unchanged", Arr (Arr'First) = 1 and Arr (Arr'Last) = 6);
   end;

   -- TEST 10 — Reverse Sorted Array
   Put_Line ("TEST 10 — Reverse Sorted Array");
   declare
      Arr : Element_Array := [10, 8, 6, 4, 2, 0];
   begin
      Check ("10.1 Reverse sorted array is not sorted", not Is_Sorted (Arr));
      Sort_Space_Bounded (Arr);
      Check ("10.2 Space bounded sort successfully sorts reverse array", Is_Sorted (Arr));
      Check ("10.3 Bounds check holds", Arr (Arr'First) = 0);
   end;

   -- TEST 11 — Is_Sorted Function Robustness
   Put_Line ("TEST 11 — Is_Sorted Function Robustness");
   declare
      Sorted_Arr   : constant Element_Array := [10, 20, 30, 40];
      Unsorted_Arr : constant Element_Array := [10, 30, 20, 40];
      Flat_Arr     : constant Element_Array := [5, 5, 5, 5];
   begin
      Check ("11.1 Strictly non-decreasing sorted array returns True", Is_Sorted (Sorted_Arr));
      Check ("11.2 Unsorted array returns False", not Is_Sorted (Unsorted_Arr));
      Check ("11.3 Equal element array returns True", Is_Sorted (Flat_Arr));
   end;

   -- TEST 12 — Large Range Element_Value Test
   Put_Line ("TEST 12 — Large Range Element_Value Test");
   declare
      Arr : Element_Array := [-9999, 5000, -5000, 9999, 0];
   begin
      Sort_Frequency (Arr);
      Check ("12.1 Frequency sort handles extreme range values", Is_Sorted (Arr));
      Check ("12.2 Minimum extreme value is first", Arr (Arr'First) = -9999);
      Check ("12.3 Maximum extreme value is last", Arr (Arr'Last) = 9999);
   end;

   -- TEST 13 — Comprehensive Multi-Variant Consistency Test
   Put_Line ("TEST 13 — Comprehensive Multi-Variant Consistency Test");
   declare
      Base_Arr : constant Element_Array := [42, -7, 13, 0, 99, -42, 13, 5];
      Arr_A    : Element_Array := Base_Arr;
      Arr_B    : Element_Array := Base_Arr;
      Arr_C    : Element_Array := Base_Arr;
      Arr_D    : Element_Array := Base_Arr;
   begin
      Sort_Comparison (Arr_A);
      Sort_Parallel_Network (Arr_B);
      Sort_Frequency (Arr_C);
      Sort_Space_Bounded (Arr_D);
      Check ("13.1 Comparison sort variant is sorted", Is_Sorted (Arr_A));
      Check ("13.2 Parallel network sort variant is sorted", Is_Sorted (Arr_B));
      Check ("13.3 Frequency sort variant is sorted", Is_Sorted (Arr_C));
      Check ("13.4 All variants yield identical sorted output", Arr_A = Arr_B and Arr_B = Arr_C and Arr_C = Arr_D);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
            & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
