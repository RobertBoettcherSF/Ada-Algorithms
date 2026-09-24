--  Standalone test suite for Bogosort (main program).
--  CRITICAL: keep n tiny — bogosort is O(n·n!) / up to n! permutations.
--  Tests use n ≤ 8; reverse cases typically ≤ 7.

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Bogosort; use Bogosort;

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

   function Random_Array
     (Len : Natural; Lo, Hi : Integer) return Element_Array
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
      Neg   : Element_Array := [-7];
   begin
      Check (Is_Sorted (Empty), "empty Is_Sorted");
      Sort (Empty);
      Check (Is_Sorted (Empty), "empty after Sort");
      Check (Is_Sorted (One), "singleton Is_Sorted");
      Sort (One);
      Check (One (One'First) = 42, "singleton value preserved");
      Check (Is_Sorted (One), "singleton after Sort");
      Sort (Neg);
      Check (Neg (Neg'First) = -7, "negative singleton preserved");
      Check (Is_Sorted (Neg), "negative singleton Is_Sorted");
   end;

   ---------------------------------------------------------------------
   Section ("2. Small patterns (n <= 8)");
   ---------------------------------------------------------------------
   Expect_Sorted ([3, 1, 2], "tiny 3");
   Expect_Sorted ([5, 4, 3, 2, 1], "reverse 5");
   Expect_Sorted ([1, 2, 3, 4, 5], "already sorted 5");
   Expect_Sorted ([2, 2, 2, 2], "all equal 4");
   Expect_Sorted ([9, 0, 5, 1, 8, 3], "mixed with zero");
   Expect_Sorted ([1, 0], "two swapped with zero");
   Expect_Sorted ([100, 100], "two equal");
   Expect_Sorted ([2, 1, 2, 1, 2, 1], "alternating");
   Expect_Sorted ([1, 2, 3, 5, 4], "almost sorted");
   Expect_Sorted ([0, 1, 0, 1, 0, 1, 0], "binary keys");
   Expect_Sorted ([0, 0, 0, 0], "all zeros");
   Expect_Sorted ([7], "singleton via Expect");
   Expect_Sorted ([6, 5, 4, 3, 2, 1], "reverse 6");
   Expect_Sorted ([7, 6, 5, 4, 3, 2, 1], "reverse 7");
   Expect_Sorted ([1, 3, 5, 7, 2, 4, 6], "odds then evens 7");
   Expect_Sorted ([8, 1, 2, 3, 4, 5, 6, 7], "rotated 8");

   ---------------------------------------------------------------------
   Section ("3. Negatives and duplicates");
   ---------------------------------------------------------------------
   Expect_Sorted ([-3, -1, -2], "three negatives");
   Expect_Sorted ([-5, 0, 5, -2, 2], "negatives mixed");
   Expect_Sorted ([-1, -1, -1], "all equal negatives");
   Expect_Sorted ([5, 3, 5, 3, 5, 1, 1], "many dups");
   Expect_Sorted ([7, 7, 7, 1, 1, 9, 9], "runs of equals");
   Expect_Sorted ([-10, 10, -5, 5, 0], "symmetric around zero");
   Expect_Sorted ([4, 4, 4, 2, 2, 2, 4, 2], "two-value multiset");
   Expect_Sorted ([10, 1, 10, 1, 10, 1], "high-low alternating");
   Expect_Sorted ([-8, -3, -1, -2, -5, -4], "all negatives scrambled");

   ---------------------------------------------------------------------
   Section ("4. Arbitrary bounds (non-1 First)");
   ---------------------------------------------------------------------
   declare
      A : Element_Array (0 .. 4) :=
        [0 => 4, 1 => 1, 2 => 3, 3 => 2, 4 => 0];
      R : Element_Array := Copy_Of (A);
   begin
      Sort (A);
      Reference_Sort (R);
      Check (Is_Sorted (A), "0-based Is_Sorted");
      Check (Same (A, R), "0-based matches reference");
      Check (A'First = 0 and then A'Last = 4, "0-based bounds preserved");
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
   declare
      A : Element_Array (100 .. 102) :=
        [100 => 3, 101 => 1, 102 => 2];
   begin
      Sort (A);
      Check (A (100) = 1 and then A (101) = 2 and then A (102) = 3,
             "100-based values placed");
   end;

   ---------------------------------------------------------------------
   Section ("5. Random arrays vs reference (tiny n only)");
   ---------------------------------------------------------------------
   Expect_Sorted (Random_Array (3, 0, 9), "random n=3 range 0..9");
   Expect_Sorted (Random_Array (4, -10, 20), "random n=4 signed");
   Expect_Sorted (Random_Array (5, 1, 5), "random n=5 range 1..5");
   Expect_Sorted (Random_Array (6, -3, 3), "random n=6 range -3..3");
   Expect_Sorted (Random_Array (7, 0, 0), "random n=7 all-zero span");
   Expect_Sorted (Random_Array (7, -5, 5), "random n=7 tiny");
   Expect_Sorted (Random_Array (5, 90, 100), "random n=5 high band");
   Expect_Sorted (Random_Array (6, -100, 100), "random n=6 wide");
   Expect_Sorted (Random_Array (8, 0, 3), "random n=8 few keys");
   Expect_Sorted (Random_Array (4, -2, 2), "random n=4 again");

   ---------------------------------------------------------------------
   Section ("6. Is_Sorted predicate");
   ---------------------------------------------------------------------
   Check (Is_Sorted ([1, 2, 3, 4]), "ascending true");
   Check (Is_Sorted ([1, 1, 2, 2]), "nondecreasing true");
   Check (not Is_Sorted ([1, 3, 2]), "inversion false");
   Check (not Is_Sorted ([5, 4, 3]), "reverse false");
   Check (Is_Sorted ([7]), "singleton true");
   Check (Is_Sorted ([0, 0, 0]), "zeros nondecreasing");
   Check (not Is_Sorted ([0, 2, 1]), "zero then inversion false");
   Check (Is_Sorted ([-3, -2, -1, 0]), "negatives ascending");
   Check (not Is_Sorted ([-1, -3]), "negatives inversion false");
   declare
      E : Element_Array (1 .. 0);
   begin
      Check (Is_Sorted (E), "empty true");
   end;

   ---------------------------------------------------------------------
   Section ("7. Invalid_Argument — oversize n");
   ---------------------------------------------------------------------
   declare
      Huge : constant Element_Array (1 .. Max_N + 1) := [others => 0];
   begin
      Check (Sort_Raises (Huge), "n = Max_N+1 raises");
   end;
   declare
      Bigger : constant Element_Array (1 .. Max_N + 10) := [others => 1];
   begin
      Check (Sort_Raises (Bigger), "n = Max_N+10 raises");
   end;
   --  Do NOT call Sort on Max_N (=10) with a hard permutation — n! = 3.6M.
   declare
      Ok : Element_Array (1 .. 8) := [others => 3];
   begin
      Sort (Ok);
      Check (Is_Sorted (Ok), "n=8 all equal sorts (under Max_N)");
   end;
   declare
      Tiny : Element_Array (1 .. 2) := [1, 0];
   begin
      Check (not Sort_Raises (Tiny), "n=2 under Max_N does not raise");
      Sort (Tiny);
      Check (Tiny (1) = 0 and then Tiny (2) = 1, "n=2 values after Sort");
   end;
   declare
      At_Cap_Sorted : Element_Array (1 .. Max_N);
   begin
      for I in At_Cap_Sorted'Range loop
         At_Cap_Sorted (I) := I;
      end loop;
      Check (not Sort_Raises (At_Cap_Sorted),
             "n = Max_N already-sorted accepted");
      Sort (At_Cap_Sorted);
      Check (Is_Sorted (At_Cap_Sorted), "n = Max_N sorted stays sorted");
   end;

   ---------------------------------------------------------------------
   Section ("8. Edge patterns");
   ---------------------------------------------------------------------
   Expect_Sorted ([1, 2], "two ascending");
   Expect_Sorted ([2, 1], "two descending");
   Expect_Sorted ([0, 0], "two zeros");
   Expect_Sorted ([-100, 100, -50], "sparse signed");
   Expect_Sorted ([1, 3, 5, 7, 2, 4, 6, 8], "odds then evens 8");
   Expect_Sorted ([8, 0, 8, 0, 8, 0, 8, 0], "sparse high/zero");
   declare
      A : Element_Array (1 .. 7);
   begin
      for I in A'Range loop
         A (I) := I;
      end loop;
      Expect_Sorted (A, "identity 1..7");
   end;
   declare
      A : Element_Array (1 .. 7);
   begin
      for I in A'Range loop
         A (I) := 8 - I;
      end loop;
      Expect_Sorted (A, "countdown 7..1");
   end;
   Expect_Sorted ([Integer'First / 4, 0, Integer'Last / 4, -1, 1],
                  "large magnitude ints");
   Expect_Sorted ([4, 1, 3, 2], "permute 4");
   Expect_Sorted ([3, 2, 1], "reverse 3");
   Expect_Sorted ([9, 8, 7, 6, 5], "countdown 5");

   ---------------------------------------------------------------------
   Section ("9. Idempotence");
   ---------------------------------------------------------------------
   declare
      A : Element_Array := [9, 3, 7, 1, 5, 0, 4];
   begin
      Sort (A);
      declare
         B : constant Element_Array := Copy_Of (A);
      begin
         Sort (A);
         Check (Same (A, B), "second Sort is no-op on sorted");
         Check (Is_Sorted (A), "idempotent still sorted");
      end;
   end;
   declare
      A : Element_Array := [1, 2, 3, 4, 5, 6];
   begin
      Sort (A);
      declare
         B : constant Element_Array := Copy_Of (A);
      begin
         Sort (A);
         Check (Same (A, B), "idempotent on already-sorted input");
      end;
   end;
   declare
      A : Element_Array := [4, 3, 2, 1];
   begin
      Sort (A);
      declare
         B : constant Element_Array := Copy_Of (A);
      begin
         Sort (A);
         Check (Same (A, B), "idempotent after reverse-4");
      end;
   end;

   New_Line;
   Put_Line
     ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image
      & " FAIL");

   if Fail_Count /= 0 then
      raise Program_Error with "Bogosort tests failed";
   end if;
end Tests;
