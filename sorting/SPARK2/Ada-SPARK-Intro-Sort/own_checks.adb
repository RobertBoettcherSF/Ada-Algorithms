--  Own property tests for Intro_Sort (written for this repository; see
--  tests/SOURCES.txt). No expected value is taken from the program.
--  Sort is checked as a sort (output nondecreasing, a permutation of the
--  input, equal to the own insertion sort below). Partition is checked as
--  one Lomuto step around the last element. Heapify is checked as one
--  Floyd build: a permutation and a max-heap. Hand-worked layouts are not
--  fully sorted, so the old adjacent compare-exchange passes do not match
--  them. Sort_Limited with a depth below Depth_Limit forces the heapsort
--  fallback; with Depth_Limit itself that fallback is not reached.
pragma Ada_2022;
with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Intro_Sort; use Intro_Sort;

procedure Own_Checks is
   Failures : Natural := 0;
   Cases    : Natural := 0;

   --  Park-Miller "minimal standard" generator (x := 16807 x mod (2**31 - 1)).
   --  Random test inputs: fixed default seed, printed at start; AA_SEED=<n> overrides it.
   function AA_Seed (Default : Long_Long_Integer) return Long_Long_Integer is
      V : constant String := Ada.Environment_Variables.Value ("AA_SEED", "");
      S : Long_Long_Integer := Default;
   begin
      if V /= "" then
         S := Long_Long_Integer (1 + abs (Long_Long_Integer'Value (V)) mod 2_147_483_646);
      end if;
      Ada.Text_IO.Put_Line ("AA_SEED =" & Long_Long_Integer'Image (S) & (if V = "" then " (default)" else " (from AA_SEED)"));
      return S;
   end AA_Seed;
   Seed : Long_Long_Integer := AA_Seed (20_261_008);
   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Lo + Integer (Seed mod Long_Long_Integer (Hi - Lo + 1));
   end Next;

   --  Own reference: straight insertion sort.
   function Reference (A : Input_Array) return Input_Array is
      B : Input_Array := A;
      T : Value;
      J : Index;
   begin
      for I in Index'First + 1 .. Index'Last loop
         T := B (I);
         J := I;
         while J > Index'First and then B (J - 1) > T loop
            B (J) := B (J - 1);
            J := J - 1;
         end loop;
         B (J) := T;
      end loop;
      return B;
   end Reference;

   --  Max-heap on length 8: parent I >= children 2*I and 2*I+1.
   function Heap_OK (A : Input_Array) return Boolean is
      Ok : Boolean := True;
   begin
      for I in Index loop
         if 2 * I in Index and then A (I) < A (2 * I) then
            Ok := False;
         end if;
         if 2 * I + 1 in Index and then A (I) < A (2 * I + 1) then
            Ok := False;
         end if;
      end loop;
      return Ok;
   end Heap_OK;

   function Sorted_OK (A : Input_Array) return Boolean is
     (for all I in Index'First .. Index'Last - 1 => A (I) <= A (I + 1));

   --  True when the array is already a Lomuto split on the last element:
   --  some index holds that value, the left is <= it, and the right is >= it.
   function Already_Partitioned (A : Input_Array) return Boolean is
      Pivot : constant Value := A (Index'Last);
      Found : Boolean := False;
   begin
      for P in Index loop
         if A (P) = Pivot then
            declare
               Ok : Boolean := True;
            begin
               for I in Index loop
                  if I < P and then A (I) > Pivot then
                     Ok := False;
                  end if;
                  if I > P and then A (I) < Pivot then
                     Ok := False;
                  end if;
               end loop;
               if Ok then
                  Found := True;
               end if;
            end;
         end if;
      end loop;
      return Found;
   end Already_Partitioned;

   procedure Check_One (A : Input_Array; Label : String) is
      R      : constant Input_Array := Sort (A);
      type Counts is array (Value) of Natural;
      C_In   : Counts := [others => 0];
      C_Out  : Counts := [others => 0];
      Ok     : Boolean := True;
      Traced          : Input_Array;
      Used            : Boolean;
      Unsorted_Heap   : Boolean;
   begin
      Cases := Cases + 1;
      for I in Index loop
         C_In (A (I)) := C_In (A (I)) + 1;
         C_Out (R (I)) := C_Out (R (I)) + 1;
         if I < Index'Last and then R (I) > R (I + 1) then
            Ok := False;
         end if;
      end loop;
      Sort_Limited (A, Depth_Limit, Traced, Used, Unsorted_Heap);
      if C_In /= C_Out or else R /= Reference (A) or else Traced /= R
        or else Used or else Unsorted_Heap
      then
         Ok := False;
      end if;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 5 then
            Put ("  FAIL own check (" & Label & "): input");
            for X of A loop
               Put (X'Image);
            end loop;
            New_Line;
         end if;
      end if;
   end Check_One;

   --  Core step. Left of the pivot index is <= the pivot value and the
   --  right is >= it. The pivot value is the original last element.
   procedure Check_Partition (A : Input_Array; Label : String) is
      B  : Input_Array;
      P  : Index;
      type Counts is array (Value) of Natural;
      C_In  : Counts := [others => 0];
      C_Out : Counts := [others => 0];
      Ok    : Boolean := True;
   begin
      Cases := Cases + 1;
      Partition (A, B, P);
      for I in Index loop
         C_In (A (I)) := C_In (A (I)) + 1;
         C_Out (B (I)) := C_Out (B (I)) + 1;
         if I < P and then B (I) > B (P) then
            Ok := False;
         end if;
         if I > P and then B (I) < B (P) then
            Ok := False;
         end if;
      end loop;
      if C_In /= C_Out or else B (P) /= A (Index'Last) then
         Ok := False;
      end if;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 5 then
            Put ("  FAIL partition (" & Label & "): input");
            for X of A loop
               Put (X'Image);
            end loop;
            Put (" pivot" & P'Image & " value" & B (P)'Image);
            New_Line;
         end if;
      end if;
   end Check_Partition;

   --  Hand-worked one-step layout. These results are not sorted, so the
   --  old compare-exchange Sort (which returns a sorted array) fails.
   procedure Check_Layout
     (A : Input_Array; Expected : Input_Array; Expected_Pivot : Index; Label : String)
   is
      B : Input_Array;
      P : Index;
   begin
      Cases := Cases + 1;
      Partition (A, B, P);
      if Already_Partitioned (A) or else Sorted_OK (Expected)
        or else B /= Expected or else P /= Expected_Pivot
      then
         Failures := Failures + 1;
         if Failures <= 5 then
            Put ("  FAIL partition layout (" & Label & "): got");
            for X of B loop
               Put (X'Image);
            end loop;
            Put (" pivot" & P'Image & " expected");
            for X of Expected loop
               Put (X'Image);
            end loop;
            Put (" pivot" & Expected_Pivot'Image);
            New_Line;
         end if;
      end if;
   end Check_Layout;

   Saw_Non_Heap : Boolean := False;
   Saw_Unsorted : Boolean := False;

   procedure Check_Heap (A : Input_Array; Label : String) is
      B : Input_Array := A;
      type Counts is array (Value) of Natural;
      C_In  : Counts := [others => 0];
      C_Out : Counts := [others => 0];
      Ok    : Boolean := True;
   begin
      Cases := Cases + 1;
      if not Heap_OK (A) then
         Saw_Non_Heap := True;
      end if;
      Heapify (B);
      for I in Index loop
         C_In (A (I)) := C_In (A (I)) + 1;
         C_Out (B (I)) := C_Out (B (I)) + 1;
      end loop;
      if C_In /= C_Out or else not Heap_OK (B) then
         Ok := False;
      end if;
      if Heap_OK (B) and then not Sorted_OK (B) then
         Saw_Unsorted := True;
      end if;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 5 then
            Put ("  FAIL heapify (" & Label & "): input");
            for X of A loop
               Put (X'Image);
            end loop;
            Put (" got");
            for X of B loop
               Put (X'Image);
            end loop;
            New_Line;
         end if;
      end if;
   end Check_Heap;

   --  Hand-worked Floyd layout. The expected array is not sorted, so the
   --  old compare-exchange passes (which return a sorted array) fail.
   procedure Check_Heap_Layout (A, Expected : Input_Array; Label : String) is
      B : Input_Array := A;
   begin
      Cases := Cases + 1;
      Heapify (B);
      if Sorted_OK (Expected) or else B /= Expected or else not Heap_OK (B) then
         Failures := Failures + 1;
         if Failures <= 5 then
            Put ("  FAIL heapify layout (" & Label & "): got");
            for X of B loop
               Put (X'Image);
            end loop;
            Put (" expected");
            for X of Expected loop
               Put (X'Image);
            end loop;
            New_Line;
         end if;
      else
         Saw_Unsorted := True;
      end if;
   end Check_Heap_Layout;

   --  Heapsort of one slice: the slice is sorted, it is a permutation of
   --  the original slice, and cells outside the slice stay put.
   procedure Check_Heap_Range (A : Input_Array; Lo, Hi : Index; Label : String) is
      B : Input_Array := A;
      type Counts is array (Value) of Natural;
      C_In  : Counts := [others => 0];
      C_Out : Counts := [others => 0];
      Ok    : Boolean := True;
   begin
      Cases := Cases + 1;
      Heap_Sort_Range (B, Lo, Hi);
      for I in Index loop
         if I < Lo or else I > Hi then
            if B (I) /= A (I) then
               Ok := False;
            end if;
         else
            C_In (A (I)) := C_In (A (I)) + 1;
            C_Out (B (I)) := C_Out (B (I)) + 1;
            if I < Hi and then B (I) > B (I + 1) then
               Ok := False;
            end if;
         end if;
      end loop;
      if C_In /= C_Out then
         Ok := False;
      end if;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 5 then
            Put ("  FAIL heap range (" & Label & "): got");
            for X of B loop
               Put (X'Image);
            end loop;
            New_Line;
         end if;
      end if;
   end Check_Heap_Range;

   --  Forced depth. Depth 0 heapsorts the whole array. A positive depth
   --  below the normal budget can heapsort a proper slice.
   procedure Check_Forced
     (A : Input_Array; Depth : Natural; Expect_Heap, Expect_Unsorted : Boolean; Label : String)
   is
      B             : Input_Array;
      Used          : Boolean;
      Unsorted_Heap : Boolean;
      type Counts is array (Value) of Natural;
      C_In  : Counts := [others => 0];
      C_Out : Counts := [others => 0];
      Ok    : Boolean := True;
   begin
      Cases := Cases + 1;
      Sort_Limited (A, Depth, B, Used, Unsorted_Heap);
      for I in Index loop
         C_In (A (I)) := C_In (A (I)) + 1;
         C_Out (B (I)) := C_Out (B (I)) + 1;
         if I < Index'Last and then B (I) > B (I + 1) then
            Ok := False;
         end if;
      end loop;
      if C_In /= C_Out or else B /= Reference (A)
        or else Used /= Expect_Heap or else Unsorted_Heap /= Expect_Unsorted
      then
         Ok := False;
      end if;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 8 then
            Put ("  FAIL forced depth (" & Label & "): used" & Used'Image
                 & " unsorted" & Unsorted_Heap'Image & " got");
            for X of B loop
               Put (X'Image);
            end loop;
            New_Line;
         end if;
      end if;
   end Check_Forced;

   A : Input_Array;
begin
   --  1. Every 0/1 input (2**8): for comparator networks this alone proves
   --     the network sorts all inputs (0-1 principle, Knuth TAOCP 5.3.4).
   for Mask in 0 .. 2 ** Index'Last - 1 loop
      for I in Index loop
         A (I) := (if (Mask / 2 ** (I - 1)) mod 2 = 1 then 1 else 0);
      end loop;
      Check_One (A, "0/1 mask" & Mask'Image);
      Check_Partition (A, "0/1 mask" & Mask'Image);
      Check_Heap (A, "0/1 mask" & Mask'Image);
   end loop;
   --  2. Edge shapes: all equal, ascending, descending, extremes.
   Check_One ([others => Value'First], "all First");
   Check_One ([others => Value'Last], "all Last");
   Check_One ([for I in Index => Value'First + (I - 1)], "ascending");
   Check_One ([for I in Index => Value'Last - (I - 1)], "descending");
   Check_One ([for I in Index => (if I mod 2 = 0 then Value'First else Value'Last)], "alternating extremes");
   Check_Partition ([others => Value'First], "all First");
   Check_Partition ([others => Value'Last], "all Last");
   Check_Partition ([for I in Index => Value'First + (I - 1)], "ascending");
   Check_Partition ([for I in Index => Value'Last - (I - 1)], "descending");
   Check_Partition ([for I in Index => (if I mod 2 = 0 then Value'First else Value'Last)], "alternating extremes");
   Check_Heap ([others => Value'First], "all First");
   Check_Heap ([others => Value'Last], "all Last");
   Check_Heap ([for I in Index => Value'First + (I - 1)], "ascending");
   Check_Heap ([for I in Index => Value'Last - (I - 1)], "descending");
   Check_Heap ([for I in Index => (if I mod 2 = 0 then Value'First else Value'Last)], "alternating extremes");
   --  Hand-worked Lomuto layouts (pivot = last element). Each result still
   --  has an inversion, and none of the inputs is already partitioned.
   Check_Layout ([4, 1, 3, 2, 8, 5, 7, 6], [4, 1, 3, 2, 5, 6, 7, 8], 6, "hand 4 1 3 2 8 5 7 6");
   Check_Layout ([8, 7, 6, 5, 4, 3, 2, 1], [1, 7, 6, 5, 4, 3, 2, 8], 1, "hand reverse");
   Check_Layout ([23, 4, 17, 9, 1, 31, 12, 6], [4, 1, 6, 9, 23, 31, 12, 17], 3, "hand tests example");
   --  Hand-worked Floyd builds. Each result still has an inversion.
   --  Ascending is not already a max-heap, so a no-op Heapify fails it.
   Check_Heap_Layout
     ([1, 2, 3, 4, 5, 6, 7, 8], [8, 5, 7, 4, 1, 6, 3, 2], "hand ascending");
   Check_Heap_Layout
     ([8, 7, 6, 5, 4, 3, 2, 1], [8, 7, 6, 5, 4, 3, 2, 1], "hand reverse");
   Check_Heap_Layout
     ([4, 1, 3, 2, 8, 5, 7, 6], [8, 6, 7, 4, 1, 5, 3, 2], "hand 4 1 3 2 8 5 7 6");
   Check_Heap_Layout
     ([23, 4, 17, 9, 1, 31, 12, 6], [31, 9, 23, 6, 1, 17, 12, 4], "hand tests example");
   if Heap_OK ([1, 2, 3, 4, 5, 6, 7, 8]) then
      Failures := Failures + 1;
      Put_Line ("  FAIL ascending input was already a max-heap");
   else
      Saw_Non_Heap := True;
   end if;
   Cases := Cases + 1;
   Check_One ([4, 1, 3, 2, 8, 5, 7, 6], "layout input 1");
   Check_One ([8, 7, 6, 5, 4, 3, 2, 1], "layout input reverse");
   Check_One ([23, 4, 17, 9, 1, 31, 12, 6], "layout input example");
   Check_One ([1, 2, 3, 4, 5, 6, 7, 8], "layout input ascending");
   --  Slice heapsort: outside the slice is unchanged.
   Check_Heap_Range ([9, 4, 1, 7, 3, 8, 2, 5], 3, 6, "slice 3 .. 6");
   Check_Heap_Range ([8, 7, 6, 5, 4, 3, 2, 1], 1, 8, "full reverse");
   Check_Heap_Range ([1, 2, 3, 4, 5, 6, 7, 8], 2, 8, "slice 2 .. 8 ascending");
   Check_Heap_Range ([4, 1, 3, 2, 8, 5, 7, 6], 1, 1, "single cell");
   --  Depth budget 6 never reaches the heapsort fallback on length 8:
   --  every path hits the insertion cutoff of 2 while depth is still
   --  positive (Check_One). A smaller budget does reach it.
   --  Depth 0 heapsorts the whole array. Ascending is not a sorted heap
   --  after Heapify, so a compare-exchange Heapify fails Expect_Unsorted.
   Check_Forced ([1, 2, 3, 4, 5, 6, 7, 8], 0, True, True, "depth 0 ascending");
   Check_Forced ([8, 7, 6, 5, 4, 3, 2, 1], 0, True, True, "depth 0 reverse");
   Check_Forced ([others => 0], 0, True, False, "depth 0 all equal");
   --  Depth 1 on the reverse array partitions once, then heapsorts 2 .. 8.
   Check_Forced ([8, 7, 6, 5, 4, 3, 2, 1], 1, True, True, "depth 1 reverse slice");
   Check_Forced ([4, 1, 3, 2, 8, 5, 7, 6], 2, True, True, "depth 2 mixed");
   --  3. Random inputs over the whole Value range, and with many duplicates.
   for K in 1 .. 2_000 loop
      for I in Index loop
         A (I) := Next (Value'First, Value'Last);
      end loop;
      Check_One (A, "random" & K'Image);
      Check_Partition (A, "random" & K'Image);
      Check_Heap (A, "random" & K'Image);
   end loop;
   for K in 1 .. 1_000 loop
      for I in Index loop
         A (I) := Next (Value'First, Value'First + 2);
      end loop;
      Check_One (A, "duplicates" & K'Image);
      Check_Partition (A, "duplicates" & K'Image);
      Check_Heap (A, "duplicates" & K'Image);
   end loop;

   if not Saw_Non_Heap or else not Saw_Unsorted then
      Failures := Failures + 1;
      Cases := Cases + 1;
      Put_Line ("  FAIL heapify suite did not include a non-heap input and an unsorted heap");
   end if;

   if Failures > 0 then
      Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Put_Line ("PASS own checks:" & Cases'Image
             & " inputs (sorted, permutation, own reference, partition, heapify, heap fallback)");
end Own_Checks;
