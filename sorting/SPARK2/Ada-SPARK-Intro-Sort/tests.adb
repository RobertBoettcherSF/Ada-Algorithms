pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Intro_Sort; use Intro_Sort;
with Own_Checks;
procedure Tests is
   Failures : Natural := 0;

   function Sorted_OK (A : Input_Array) return Boolean is
     (for all I in Index'First .. Index'Last - 1 => A (I) <= A (I + 1));

   --  Same Partition_Range that Sort_Range calls.
   procedure Check_Layout
     (A : Input_Array; Expected : Input_Array; Expected_Pivot : Index; Label : String)
   is
      B : Input_Array := A;
      P : Index;
   begin
      Partition_Range (B, Index'First, Index'Last, P);
      if B /= Expected or else P /= Expected_Pivot then
         Failures := Failures + 1;
         Put_Line ("  FAIL partition layout (" & Label & ")");
      end if;
   end Check_Layout;

   --  Same Heapify the length-8 heapsort fallback calls.
   procedure Check_Heap (A, Expected : Input_Array; Label : String) is
      B : Input_Array := A;
   begin
      Heapify (B);
      if Sorted_OK (Expected) or else Sorted_OK (B) or else B /= Expected
        or else not Is_Max_Heap (B)
      then
         Failures := Failures + 1;
         Put_Line ("  FAIL heapify layout (" & Label & ")");
      end if;
   end Check_Heap;

   Example   : constant Input_Array := [23, 4, 17, 9, 1, 31, 12, 6];
   Ascending : constant Input_Array := [1, 2, 3, 4, 5, 6, 7, 8];
   Own_Failed : Boolean := False;
begin
   if Is_Max_Heap (Ascending) then
      Failures := Failures + 1;
      Put_Line ("  FAIL ascending input was already a max-heap");
   end if;

   Check_Layout ([4, 1, 3, 2, 8, 5, 7, 6], [4, 1, 3, 2, 5, 6, 7, 8], 6, "hand 4 1 3 2 8 5 7 6");
   Check_Layout ([8, 7, 6, 5, 4, 3, 2, 1], [1, 7, 6, 5, 4, 3, 2, 8], 1, "hand reverse");
   Check_Layout (Example, [4, 1, 6, 9, 23, 31, 12, 17], 3, "hand tests example");

   Check_Heap (Ascending, [8, 5, 7, 4, 1, 6, 3, 2], "hand ascending");
   Check_Heap ([8, 7, 6, 5, 4, 3, 2, 1], [8, 7, 6, 5, 4, 3, 2, 1], "hand reverse");
   Check_Heap ([4, 1, 3, 2, 8, 5, 7, 6], [8, 6, 7, 4, 1, 5, 3, 2], "hand 4 1 3 2 8 5 7 6");
   Check_Heap (Example, [31, 9, 23, 6, 1, 17, 12, 4], "hand tests example");

   declare
      B             : Input_Array;
      Used          : Boolean;
      Unsorted_Heap : Boolean;
   begin
      Sort_Limited (Example, Depth_Limit, B, Used, Unsorted_Heap);
      if Used or else Unsorted_Heap or else not Sorted_OK (B) then
         Failures := Failures + 1;
         Put_Line ("  FAIL depth budget 6 took the heapsort fallback");
      end if;
      Sort_Limited (Ascending, 0, B, Used, Unsorted_Heap);
      if not Used or else not Unsorted_Heap or else not Sorted_OK (B) then
         Failures := Failures + 1;
         Put_Line ("  FAIL Sort_Limited 0 did not heapsort an unsorted heap");
      end if;
   end;

   begin
      Own_Checks;
   exception
      when Program_Error =>
         Own_Failed := True;
   end;

   if Failures > 0 or else Own_Failed then
      if Failures > 0 then
         Put_Line ("FAIL Intro_Sort:" & Failures'Image);
      else
         Put_Line ("FAIL Intro_Sort");
      end if;
      raise Program_Error with "tests failed";
   end if;
   Put_Line ("PASS Intro_Sort");
end Tests;
