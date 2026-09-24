--  Standalone test suite for Heapsort (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Heapsort; use Heapsort;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Condition : Boolean; Message : String) is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      New_Line;
      Put_Line ("=== " & Title & " ===");
   end Section;

   --  Insertion-sort reference (ascending).
   procedure Reference_Sort (A : in out Element_Array) is
   begin
      if A'Length <= 1 then
         return;
      end if;
      for I in A'First + 1 .. A'Last loop
         declare
            Key : constant Integer := A (I);
            J   : Integer := Integer (I) - 1;
         begin
            while J >= Integer (A'First) and then A (J) > Key loop
               A (J + 1) := A (J);
               J := J - 1;
            end loop;
            A (J + 1) := Key;
         end;
      end loop;
   end Reference_Sort;

   function Same (A, B : Element_Array) return Boolean is
   begin
      if A'Length /= B'Length then
         return False;
      end if;
      for I in A'Range loop
         if A (I) /= B (I - A'First + B'First) then
            return False;
         end if;
      end loop;
      return True;
   end Same;

   function Copy_Of (A : Element_Array) return Element_Array is
   begin
      return Element_Array'(A);
   end Copy_Of;

   function Sort_Raises (A : Element_Array) return Boolean is
      T : Element_Array := A;
   begin
      Sort (T);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Sort_Raises;

   function Heapify_Raises (A : Element_Array) return Boolean is
      T : Element_Array := A;
   begin
      Heapify (T);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Heapify_Raises;

   --  True iff A (A'First .. Heap_Last) is a max-heap under First-relative
   --  child indexing.
   function Is_Max_Heap
     (A : Element_Array; Heap_Last : Natural) return Boolean
   is
      Left : Natural;
   begin
      if A'Length = 0 or else Heap_Last < A'First then
         return True;
      end if;
      for I in A'First .. Heap_Last loop
         Left := A'First + 2 * (I - A'First) + 1;
         if Left <= Heap_Last then
            if A (I) < A (Left) then
               return False;
            end if;
            if Left < Heap_Last and then A (I) < A (Left + 1) then
               return False;
            end if;
         end if;
      end loop;
      return True;
   end Is_Max_Heap;

   procedure Expect_Sorted (Src : Element_Array; Label : String) is
      A : Element_Array := Copy_Of (Src);
      R : Element_Array := Copy_Of (Src);
   begin
      Sort (A);
      Reference_Sort (R);
      Check (Is_Sorted (A), Label & " Is_Sorted");
      Check (Same (A, R), Label & " matches reference");
   end Expect_Sorted;

   --  Deterministic LCG.
   Seed : Natural := 1_234_567;

   function Next_Mod (Modulus : Positive) return Natural is
      Mult : constant := 1_103_515_245;
      Add  : constant := 12_345;
      X    : Natural;
   begin
      X := Natural ((Long_Long_Integer (Seed) * Mult + Add)
                    mod 2_147_483_647);
      Seed := X;
      return X rem Modulus;
   end Next_Mod;

   function Random_Array (Len : Natural; Lo, Hi : Integer) return Element_Array
   is
      Span : constant Positive := Hi - Lo + 1;
      A    : Element_Array (1 .. Len);
   begin
      for I in A'Range loop
         A (I) := Lo + Integer (Next_Mod (Span));
      end loop;
      return A;
   end Random_Array;

begin
   ---------------------------------------------------------------------
   Section ("1. Empty and singleton");
   ---------------------------------------------------------------------
   declare
      E : Element_Array (1 .. 0);
      S : Element_Array (1 .. 1) := [42];
      Z : Element_Array (0 .. 0) := [0 => -7];
   begin
      Check (Is_Sorted (E), "empty Is_Sorted");
      Sort (E);
      Check (Is_Sorted (E), "empty Sort no-op");
      Heapify (E);
      Check (Is_Sorted (E), "empty Heapify no-op");
      Check (Is_Sorted (S), "singleton Is_Sorted");
      Sort (S);
      Check (S (1) = 42, "singleton Sort preserves");
      Heapify (Z);
      Check (Z (0) = -7, "0-based singleton Heapify preserves");
      Sort (Z);
      Check (Z (0) = -7, "0-based singleton Sort preserves");
   end;

   ---------------------------------------------------------------------
   Section ("2. Already sorted / reverse / duplicates");
   ---------------------------------------------------------------------
   Expect_Sorted ([1, 2, 3, 4, 5], "already sorted");
   Expect_Sorted ([5, 4, 3, 2, 1], "fully reversed");
   Expect_Sorted ([3, 1, 4, 1, 5, 9, 2, 6], "pi digits");
   Expect_Sorted ([7, 7, 7, 7], "all equal");
   Expect_Sorted ([2, 1, 2, 1, 2], "alternating duplicates");
   Expect_Sorted ([0, -1, 0, -1], "zeros and negatives");

   ---------------------------------------------------------------------
   Section ("3. Classic worked example");
   ---------------------------------------------------------------------
   --  Same numeric example as selection-sort wiki demo.
   declare
      A : Element_Array := [64, 25, 12, 22, 11];
   begin
      Sort (A);
      Check (Same (A, [11, 12, 22, 25, 64]), "worked example sorts to known");
      Check (Is_Sorted (A), "worked example Is_Sorted");
   end;

   ---------------------------------------------------------------------
   Section ("4. Two-element and small permutations");
   ---------------------------------------------------------------------
   Expect_Sorted ([1, 2], "two ascending");
   Expect_Sorted ([2, 1], "two descending");
   Expect_Sorted ([1, 1], "two equal");
   Expect_Sorted ([3, 1, 2], "perm 3,1,2");
   Expect_Sorted ([2, 3, 1], "perm 2,3,1");
   Expect_Sorted ([1, 3, 2], "perm 1,3,2");

   ---------------------------------------------------------------------
   Section ("5. Negatives and extreme Integers");
   ---------------------------------------------------------------------
   Expect_Sorted ([-5, -1, -3, -2, -4], "all negatives");
   Expect_Sorted ([Integer'First, 0, Integer'Last], "extremes trio");
   Expect_Sorted
     ([Integer'Last, Integer'First, Integer'First + 1, -1],
      "extremes quartet");

   ---------------------------------------------------------------------
   Section ("6. Non-1-based bounds (First-relative children)");
   ---------------------------------------------------------------------
   declare
      A : Element_Array (0 .. 4) := [0 => 9, 1 => 3, 2 => 7, 3 => 1, 4 => 5];
      R : Element_Array (0 .. 4);
   begin
      R := A;
      Sort (A);
      Reference_Sort (R);
      Check (Is_Sorted (A), "0-based Is_Sorted");
      Check (Same (A, R), "0-based matches reference");
   end;
   declare
      A : Element_Array (10 .. 14) :=
        [10 => 4, 11 => 2, 12 => 8, 13 => 6, 14 => 0];
      R : Element_Array (10 .. 14);
   begin
      R := A;
      Sort (A);
      Reference_Sort (R);
      Check (A (10) = 0 and then A (14) = 8, "10-based first/last");
      Check (Same (A, R), "10-based matches reference");
   end;
   declare
      A : Element_Array (5 .. 9) :=
        [5 => 50, 6 => 10, 7 => 40, 8 => 20, 9 => 30];
   begin
      Heapify (A);
      Check (Is_Max_Heap (A, A'Last), "5-based Heapify is max-heap");
      Check (A (5) = 50, "5-based heap root is maximum");
   end;

   ---------------------------------------------------------------------
   Section ("7. Heapify / Sift_Down invariants");
   ---------------------------------------------------------------------
   declare
      A : Element_Array := [3, 1, 4, 1, 5, 9, 2, 6, 5];
   begin
      Heapify (A);
      Check (Is_Max_Heap (A, A'Last), "Heapify builds max-heap");
      Check (A (A'First) >= A (A'First + 1), "root >= left child");
   end;
   declare
      A : Element_Array := [1, 9, 8, 7, 6];
   begin
      --  Manually damaged root with valid child heaps: sift restores.
      Sift_Down (A, A'First, A'Last);
      Check (Is_Max_Heap (A, A'Last), "Sift_Down repairs damaged root");
      Check (A (A'First) = 9, "Sift_Down promotes maximum to root");
   end;
   declare
      A : Element_Array := [10, 8, 9, 7, 6, 5, 4];
   begin
      Check (Is_Max_Heap (A, A'Last), "prebuilt heap recognized");
      Sift_Down (A, A'First, A'Last);
      Check (Same (A, [10, 8, 9, 7, 6, 5, 4]), "Sift_Down no-op on valid heap");
   end;

   ---------------------------------------------------------------------
   Section ("8. Is_Sorted predicates");
   ---------------------------------------------------------------------
   Check (Is_Sorted ([1, 2, 2, 3]), "nondecreasing true");
   Check (not Is_Sorted ([1, 3, 2]), "unsorted ascending false");
   Check (Is_Sorted ([Integer'First, Integer'First]), "equal extremes sorted");
   Check (not Is_Sorted ([0, -1]), "descending pair not sorted");

   ---------------------------------------------------------------------
   Section ("9. Random arrays vs reference");
   ---------------------------------------------------------------------
   Expect_Sorted (Random_Array (2, -100, 100), "random n=2");
   Expect_Sorted (Random_Array (3, -100, 100), "random n=3");
   Expect_Sorted (Random_Array (5, -100, 100), "random n=5");
   Expect_Sorted (Random_Array (8, -1000, 1000), "random n=8");
   Expect_Sorted (Random_Array (16, -1000, 1000), "random n=16");
   Expect_Sorted (Random_Array (32, -50, 50), "random n=32");
   Expect_Sorted (Random_Array (64, -20, 20), "random n=64");
   Expect_Sorted (Random_Array (100, 0, 10), "random n=100 many dups");
   Expect_Sorted (Random_Array (200, -500, 500), "random n=200");
   Expect_Sorted (Random_Array (50, 1, 1), "random all identical");

   ---------------------------------------------------------------------
   Section ("10. Capacity / Invalid_Argument");
   ---------------------------------------------------------------------
   declare
      Big : constant Element_Array (1 .. Max_Length + 1) := [others => 0];
   begin
      Check (Sort_Raises (Big), "oversize Sort raises");
      Check (Heapify_Raises (Big), "oversize Heapify raises");
   end;
   declare
      Ok : Element_Array (1 .. 3) := [3, 1, 2];
   begin
      Sort (Ok);
      Check (Same (Ok, [1, 2, 3]), "under Max_Length still sorts");
   end;

   ---------------------------------------------------------------------
   Section ("11. Idempotence and extract-max phase");
   ---------------------------------------------------------------------
   declare
      A : Element_Array := [9, 4, 1, 8, 2, 7, 3];
      B : Element_Array (A'Range);
   begin
      Sort (A);
      B := A;
      Sort (A);
      Check (Same (A, B), "Sort twice is idempotent");
      Check (Is_Sorted (A), "idempotent result still sorted");
   end;
   declare
      A : Element_Array := [4, 10, 3, 5, 1];
      T : Integer;
   begin
      Heapify (A);
      Check (Is_Max_Heap (A, A'Last), "before extract max-heap");
      Check (A (A'First) = 10, "heap root is global maximum");
      --  One extract-max step (as in Sort's loop).
      T := A (A'First);
      A (A'First) := A (A'Last);
      A (A'Last) := T;
      Sift_Down (A, A'First, A'Last - 1);
      Check (A (A'Last) = 10, "extract-max places global max at end");
      Check (Is_Max_Heap (A, A'Last - 1), "heap after one extract");
   end;

   ---------------------------------------------------------------------
   Section ("12. Nearly sorted / single inversion");
   ---------------------------------------------------------------------
   Expect_Sorted ([1, 2, 3, 5, 4], "single swap near end");
   Expect_Sorted ([2, 1, 3, 4, 5], "single swap near start");
   Expect_Sorted ([1, 2, 2, 2, 1], "dups with inversion");

   New_Line;
   Put_Line
     ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image
      & " FAIL");

   if Fail_Count /= 0 then
      raise Program_Error with "Heapsort tests failed";
   end if;
end Tests;
