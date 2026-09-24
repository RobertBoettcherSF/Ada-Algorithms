--  Standalone test suite for Counting_Sort (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Counting_Sort; use Counting_Sort;

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

   --  Insertion-sort reference (ascending, stable).
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
   Seed : Natural := 42;

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
      Empty : Element_Array (1 .. 0);
      One   : Element_Array := [42];
   begin
      Check (Is_Sorted (Empty), "empty Is_Sorted");
      Sort (Empty);
      Check (Is_Sorted (Empty), "empty after Sort");
      Check (Is_Sorted (One), "singleton Is_Sorted");
      Sort (One);
      Check (One (One'First) = 42, "singleton value preserved");
      Check (Is_Sorted (One), "singleton after Sort");
   end;

   ---------------------------------------------------------------------
   Section ("2. Small ranges");
   ---------------------------------------------------------------------
   Expect_Sorted ([3, 1, 2], "tiny 3");
   Expect_Sorted ([5, 4, 3, 2, 1], "reverse 5");
   Expect_Sorted ([1, 2, 3, 4, 5], "already sorted");
   Expect_Sorted ([2, 2, 2, 2], "all equal");
   Expect_Sorted ([0], "zero singleton via Expect");
   Expect_Sorted ([9, 0, 5, 1, 8, 3], "mixed small");

   ---------------------------------------------------------------------
   Section ("3. Negatives and positives");
   ---------------------------------------------------------------------
   Expect_Sorted ([-3, -1, -2], "all negative");
   Expect_Sorted ([-5, 0, 5, -2, 3], "neg+pos");
   Expect_Sorted ([-10, -10, 10, 0, -1], "neg+pos dups");
   Expect_Sorted ([-100, 50, -50, 0, 100, -1], "wider signed");
   Expect_Sorted ([Integer'First + 10, Integer'First + 5,
                   Integer'First + 7], "near Integer'First");
   Expect_Sorted ([Integer'Last - 3, Integer'Last, Integer'Last - 1],
                  "near Integer'Last");

   ---------------------------------------------------------------------
   Section ("4. Duplicates and tagged stability");
   ---------------------------------------------------------------------
   Expect_Sorted ([5, 3, 5, 3, 5, 1, 1], "many dups");
   Expect_Sorted ([7, 7, 7, 1, 1, 9, 9, 9, 9], "runs of equals");
   Expect_Sorted ([0, 0, 0, 0, 0, 1, 0], "zeros with one");
   declare
      --  Encode (key, arrival_tag) as key*1000 + tag so equal keys keep
      --  tags in increasing order after a stable sort.
      --  Keys 2,1,2,1,2 with tags 1..5 → values 2001,1002,2003,1004,2005.
      A : Element_Array := [2001, 1002, 2003, 1004, 2005];
      R : Element_Array := Copy_Of (A);
   begin
      Sort (A);
      Reference_Sort (R);
      Check (Same (A, R), "tagged multiset matches reference");
      Check (Is_Sorted (A), "tagged array Is_Sorted");
      --  Equal key 1: tags 2 then 4; equal key 2: tags 1,3,5.
      Check (A (A'First) = 1002 and then A (A'First + 1) = 1004,
             "key-1 tags stable order");
      Check (A (A'First + 2) = 2001
             and then A (A'First + 3) = 2003
             and then A (A'First + 4) = 2005,
             "key-2 tags stable order");
   end;

   ---------------------------------------------------------------------
   Section ("5. Arbitrary bounds (non-1 First)");
   ---------------------------------------------------------------------
   declare
      A : Element_Array (0 .. 4) := [0 => 4, 1 => 1, 2 => 3, 3 => 2, 4 => 0];
      R : Element_Array := Copy_Of (A);
   begin
      Sort (A);
      Reference_Sort (R);
      Check (Is_Sorted (A), "0-based Is_Sorted");
      Check (Same (A, R), "0-based matches reference");
   end;
   declare
      A : Element_Array (10 .. 14) :=
        [10 => 8, 11 => 6, 12 => 7, 13 => 5, 14 => 9];
      R : Element_Array := Copy_Of (A);
   begin
      Sort (A);
      Reference_Sort (R);
      Check (Is_Sorted (A), "10-based Is_Sorted");
      Check (Same (A, R), "10-based matches reference");
   end;

   ---------------------------------------------------------------------
   Section ("6. Random small-range arrays");
   ---------------------------------------------------------------------
   Expect_Sorted (Random_Array (20, 0, 9), "random n=20 range 0..9");
   Expect_Sorted (Random_Array (50, -20, 20), "random n=50 range -20..20");
   Expect_Sorted (Random_Array (100, 1, 5), "random n=100 range 1..5");
   Expect_Sorted (Random_Array (64, -3, 3), "random n=64 range -3..3");
   Expect_Sorted (Random_Array (30, -100, -90), "random negative band");

   ---------------------------------------------------------------------
   Section ("7. Is_Sorted predicate");
   ---------------------------------------------------------------------
   Check (Is_Sorted ([1, 2, 3, 4]), "ascending true");
   Check (Is_Sorted ([1, 1, 2, 2]), "nondecreasing true");
   Check (not Is_Sorted ([1, 3, 2]), "inversion false");
   Check (not Is_Sorted ([5, 4, 3]), "reverse false");
   Check (Is_Sorted ([7]), "singleton true");
   declare
      E : Element_Array (1 .. 0);
   begin
      Check (Is_Sorted (E), "empty true");
   end;

   ---------------------------------------------------------------------
   Section ("8. Invalid_Argument — range too large");
   ---------------------------------------------------------------------
   declare
      Big : constant Element_Array := [0, Max_Range];
   begin
      Check (Sort_Raises (Big), "range Max_Range+1 raises");
   end;
   declare
      Big2 : constant Element_Array := [-50_000, 50_001];
   begin
      Check (Sort_Raises (Big2), "span 100002 raises");
   end;
   declare
      Ok : Element_Array := [0, Max_Range - 1];
   begin
      Sort (Ok);
      Check (Is_Sorted (Ok), "exact Max_Range span sorts");
   end;
   declare
      Neg_Wide : constant Element_Array := [-(Max_Range / 2), Max_Range / 2];
   begin
      Check (Sort_Raises (Neg_Wide), "signed wide span raises");
   end;

   ---------------------------------------------------------------------
   Section ("9. Invalid_Argument — oversize n");
   ---------------------------------------------------------------------
   declare
      Huge : constant Element_Array (1 .. Max_Length + 1) := [others => 0];
   begin
      Check (Sort_Raises (Huge), "n = Max_Length+1 raises");
   end;
   declare
      Ok_N : Element_Array (1 .. 1_000) := [others => 3];
   begin
      Sort (Ok_N);
      Check (Is_Sorted (Ok_N), "n=1000 all equal sorts");
   end;

   ---------------------------------------------------------------------
   Section ("10. Edge patterns");
   ---------------------------------------------------------------------
   Expect_Sorted ([1, 0], "two swapped");
   Expect_Sorted ([-1, 1], "two signed");
   Expect_Sorted ([100, 100], "two equal");
   Expect_Sorted ([2, 1, 2, 1, 2, 1], "alternating");
   Expect_Sorted ([1, 2, 3, 5, 4], "almost sorted");
   Expect_Sorted ([9, 8, 7, 6, 5, 4, 3, 2, 1, 0], "reverse 10");
   Expect_Sorted ([0, 1, 0, 1, 0, 1, 0], "binary keys");

   New_Line;
   Put_Line
     ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image
      & " FAIL");

   if Fail_Count /= 0 then
      raise Program_Error with "Counting_Sort tests failed";
   end if;
end Tests;
