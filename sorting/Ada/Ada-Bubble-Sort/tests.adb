--  Standalone test suite for Bubble_Sort (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Bubble_Sort; use Bubble_Sort;

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

   --  Insertion-sort reference (ascending, stable). Equal Integer values
   --  are indistinguishable, so Same still holds for Bubble_Sort vs
   --  reference.
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
   Section ("2. Small patterns");
   ---------------------------------------------------------------------
   Expect_Sorted ([3, 1, 2], "tiny 3");
   Expect_Sorted ([5, 4, 3, 2, 1], "reverse 5");
   Expect_Sorted ([1, 2, 3, 4, 5], "already sorted");
   Expect_Sorted ([2, 2, 2, 2], "all equal");
   Expect_Sorted ([9, 0, 5, 1, 8, 3], "mixed with zero");
   --  Wikipedia demo: 5 1 4 2 8
   Expect_Sorted ([5, 1, 4, 2, 8], "wikipedia 5,1,4,2,8");
   Expect_Sorted ([2, 3, 4, 5, 1], "turtle 2,3,4,5,1");
   Expect_Sorted ([1, 0], "two swapped with zero");
   Expect_Sorted ([100, 100], "two equal");
   Expect_Sorted ([2, 1, 2, 1, 2, 1], "alternating");
   Expect_Sorted ([1, 2, 3, 5, 4], "almost sorted");
   Expect_Sorted ([9, 8, 7, 6, 5, 4, 3, 2, 1, 0], "reverse 10 with zero");
   Expect_Sorted ([0, 1, 0, 1, 0, 1, 0], "binary keys");
   Expect_Sorted ([0, 0, 0, 0], "all zeros");
   Expect_Sorted ([7], "singleton via Expect");

   ---------------------------------------------------------------------
   Section ("3. Negatives and duplicates");
   ---------------------------------------------------------------------
   Expect_Sorted ([-3, -1, -2], "three negatives");
   Expect_Sorted ([-5, 0, 5, -2, 2], "negatives mixed");
   Expect_Sorted ([-1, -1, -1], "all equal negatives");
   Expect_Sorted ([5, 3, 5, 3, 5, 1, 1], "many dups");
   Expect_Sorted ([7, 7, 7, 1, 1, 9, 9, 9, 9], "runs of equals");
   Expect_Sorted ([-10, 10, -5, 5, 0], "symmetric around zero");
   Expect_Sorted ([4, 4, 4, 2, 2, 2, 4, 2], "two-value multiset");
   Expect_Sorted ([10, 1, 10, 1, 10, 1, 10], "high-low alternating");

   ---------------------------------------------------------------------
   Section ("4. Duplicate-heavy multisets");
   ---------------------------------------------------------------------
   Expect_Sorted ([5, 3, 5, 3, 5, 1, 1], "dups again");
   Expect_Sorted ([1, 1, 1, 1, 1, 1, 1, 1], "eight ones");
   Expect_Sorted ([9, 1, 9, 1, 9, 1, 9, 1, 9], "strict alternate");
   Expect_Sorted ([3, 3, 2, 2, 1, 1, 0, 0], "dup reverse pairs");
   Expect_Sorted ([8, 8, 8, 8, 1, 2, 3, 4], "block then climb");
   Expect_Sorted ([1, 1, 2, 2, 3, 3], "already sorted dups");
   Expect_Sorted ([3, 1, 3, 1, 2, 2], "mixed dups");

   ---------------------------------------------------------------------
   Section ("5. Arbitrary bounds (non-1 First)");
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
   declare
      A : Element_Array (5 .. 8) :=
        [5 => 9, 6 => 1, 7 => 8, 8 => 2];
      R : Element_Array := Copy_Of (A);
   begin
      Sort (A);
      Reference_Sort (R);
      Check (Same (A, R), "5-based matches reference");
      Check (A'First = 5, "5-based First preserved");
   end;
   declare
      A : Element_Array (0 .. 1) := [0 => 2, 1 => 1];
   begin
      Sort (A);
      Check (A (0) = 1 and then A (1) = 2, "0-based pair swapped");
   end;

   ---------------------------------------------------------------------
   Section ("6. Random arrays vs reference");
   ---------------------------------------------------------------------
   --  Keep n modest (≤ 500) because bubble sort is O(n²).
   Expect_Sorted (Random_Array (20, 0, 9), "random n=20 range 0..9");
   Expect_Sorted (Random_Array (50, -10, 20), "random n=50 range -10..20");
   Expect_Sorted (Random_Array (100, 1, 5), "random n=100 range 1..5");
   Expect_Sorted (Random_Array (64, -3, 3), "random n=64 range -3..3");
   Expect_Sorted (Random_Array (30, 90, 100), "random high band");
   Expect_Sorted (Random_Array (16, 0, 0), "random all-zero span");
   Expect_Sorted (Random_Array (40, 1, 1), "random all-ones");
   Expect_Sorted (Random_Array (25, -100, 100), "random wide signed");
   Expect_Sorted (Random_Array (80, -50, 50), "random n=80 signed");
   Expect_Sorted (Random_Array (200, -1000, 1000), "random n=200 wide");
   Expect_Sorted (Random_Array (256, 0, 255), "random n=256 bytes");
   Expect_Sorted (Random_Array (400, -50, 50), "random n=400 signed");
   Expect_Sorted (Random_Array (500, 0, 99), "random n=500 modest");
   Expect_Sorted (Random_Array (7, -5, 5), "random n=7 tiny");
   Expect_Sorted (Random_Array (12, -1000, 1000), "random n=12 wide");
   Expect_Sorted (Random_Array (3, 0, 10), "random n=3");

   ---------------------------------------------------------------------
   Section ("7. Is_Sorted predicate");
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
   Check (Is_Sorted ([1, 2]), "pair ascending true");
   Check (not Is_Sorted ([2, 1]), "pair descending false");
   Check (Is_Sorted ([-5, -5, -5]), "equal negatives true");
   declare
      E : Element_Array (1 .. 0);
   begin
      Check (Is_Sorted (E), "empty true");
   end;
   declare
      Z : constant Element_Array (0 .. 2) := [0 => 1, 1 => 0, 2 => 2];
   begin
      Check (not Is_Sorted (Z), "0-based inversion false");
   end;

   ---------------------------------------------------------------------
   Section ("8. Invalid_Argument — oversize n");
   ---------------------------------------------------------------------
   declare
      Huge : constant Element_Array (1 .. Max_N + 1) := [others => 0];
   begin
      Check (Sort_Raises (Huge), "n = Max_N+1 raises");
   end;
   declare
      Ok_N : Element_Array (1 .. 200) := [others => 3];
   begin
      Sort (Ok_N);
      Check (Is_Sorted (Ok_N), "n=200 all equal sorts");
      Check (not Sort_Raises (Ok_N), "n=200 does not raise");
   end;
   declare
      Mid : Element_Array := Random_Array (128, -20, 50);
      R   : Element_Array := Copy_Of (Mid);
   begin
      Sort (Mid);
      Reference_Sort (R);
      Check (Same (Mid, R), "n=128 random matches reference");
      Check (Is_Sorted (Mid), "n=128 Is_Sorted");
   end;
   declare
      --  Already-sorted Max_N is near-linear (one clean pass).
      Cap : Element_Array (1 .. Max_N) := [others => 0];
   begin
      Sort (Cap);
      Check (Is_Sorted (Cap), "n=Max_N all zeros sorts");
      Check (not Sort_Raises (Cap), "n=Max_N does not raise");
   end;

   ---------------------------------------------------------------------
   Section ("9. Edge patterns, lengths, bubble demos");
   ---------------------------------------------------------------------
   Expect_Sorted ([1, 2], "two ascending");
   Expect_Sorted ([2, 1], "two descending");
   Expect_Sorted ([0, 0], "two zeros");
   Expect_Sorted ([-100, 100, -50], "sparse signed");
   Expect_Sorted ([15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1],
                  "reverse 15");
   Expect_Sorted ([1, 3, 5, 7, 9, 2, 4, 6, 8, 10], "odds then evens");
   Expect_Sorted ([8, 0, 8, 0, 8, 0, 8, 0], "sparse high/zero");
   Expect_Sorted ([1, 10, 2, 20, 3, 30, 4, 40], "two interleaved runs");
   Expect_Sorted ([100, 1, 99, 2, 98, 3, 97, 4, 96, 5], "sawtooth");
   Expect_Sorted ([1, 2, 4, 8, 16, 32, 64, 128, 256, 3],
                  "powers then disrupt");
   Expect_Sorted ([5, 4, 3, 2, 1, 0, -1, -2], "strict reverse signed");
   Expect_Sorted ([50, 40, 30, 20, 10, 1, 2, 3], "turtles at end");
   Expect_Sorted ([9, 8, 7, 6, 5, 4, 3, 2, 1, -100], "deep turtle last");
   declare
      A : Element_Array (1 .. 10);
   begin
      for I in A'Range loop
         A (I) := I;
      end loop;
      Expect_Sorted (A, "identity 1..10");
   end;
   declare
      A : Element_Array (1 .. 10);
   begin
      for I in A'Range loop
         A (I) := 11 - I;
      end loop;
      Expect_Sorted (A, "countdown 10..1");
   end;
   declare
      A : Element_Array (1 .. 64);
   begin
      for I in A'Range loop
         A (I) := I;
      end loop;
      Expect_Sorted (A, "already sorted n=64");
   end;
   declare
      A : Element_Array (1 .. 32);
   begin
      for I in A'Range loop
         A (I) := 33 - I;
      end loop;
      Expect_Sorted (A, "reverse n=32");
   end;
   declare
      A : Element_Array (1 .. 17);
   begin
      for I in A'Range loop
         A (I) := 18 - I;
      end loop;
      Expect_Sorted (A, "odd length reverse 17");
   end;
   declare
      A : Element_Array (1 .. 16);
   begin
      for I in A'Range loop
         if I rem 2 = 1 then
            A (I) := 100 + I;
         else
            A (I) := I;
         end if;
      end loop;
      Expect_Sorted (A, "odd-high even-low n=16");
   end;
   declare
      A : Element_Array (1 .. 50);
   begin
      for I in A'Range loop
         A (I) := I;
      end loop;
      A (25) := 1;
      A (1) := 25;
      Expect_Sorted (A, "nearly sorted n=50 one swap");
   end;
   declare
      --  Organ-pipe: 1,2,...,k,...,2,1
      A : Element_Array (1 .. 21);
   begin
      for I in 1 .. 11 loop
         A (I) := I;
      end loop;
      for I in 12 .. 21 loop
         A (I) := 22 - I;
      end loop;
      Expect_Sorted (A, "organ-pipe n=21");
   end;
   declare
      A : Element_Array (1 .. 9);
   begin
      for I in A'Range loop
         A (I) := (I rem 3) * 10 + I;
      end loop;
      Expect_Sorted (A, "mod-3 mix n=9");
   end;

   ---------------------------------------------------------------------
   Section ("10. Idempotence");
   ---------------------------------------------------------------------
   declare
      A : Element_Array := [9, 3, 7, 1, 5, 0, 4, -2];
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
      A : Element_Array := [4, 4, 1, 1, 3, 3];
   begin
      Sort (A);
      declare
         B : constant Element_Array := Copy_Of (A);
      begin
         Sort (A);
         Check (Same (A, B), "idempotent on duplicates");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("11. Reverse / modest n and large magnitude");
   ---------------------------------------------------------------------
   Expect_Sorted ([Integer'First / 4, 0, Integer'Last / 4, -1, 1],
                  "large magnitude ints");
   Expect_Sorted ([Integer'First, Integer'Last, 0], "extreme pair with zero");
   Expect_Sorted ([Integer'Last, Integer'First], "Last then First");
   declare
      A : Element_Array (1 .. 100);
   begin
      for I in A'Range loop
         A (I) := 101 - I;
      end loop;
      Expect_Sorted (A, "reverse n=100");
   end;
   declare
      A : Element_Array (1 .. 200);
   begin
      for I in A'Range loop
         A (I) := I;
      end loop;
      Expect_Sorted (A, "already sorted n=200");
   end;
   declare
      A : Element_Array (1 .. 250);
   begin
      for I in A'Range loop
         A (I) := 251 - I;
      end loop;
      Expect_Sorted (A, "reverse n=250");
   end;
   declare
      A : Element_Array (1 .. 500);
   begin
      for I in A'Range loop
         A (I) := 501 - I;
      end loop;
      Expect_Sorted (A, "reverse n=500 modest");
   end;
   declare
      A : Element_Array (1 .. 63);
   begin
      for I in A'Range loop
         A (I) := (I * 17) rem 63;
      end loop;
      Expect_Sorted (A, "linear congruential n=63");
   end;
   Expect_Sorted ([0], "zero singleton via Expect");
   Expect_Sorted ([-42], "neg singleton via Expect");

   New_Line;
   Put_Line
     ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image
      & " FAIL");

   if Fail_Count /= 0 then
      raise Program_Error with "Bubble_Sort tests failed";
   end if;
end Tests;
