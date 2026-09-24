--  Standalone test suite for Quicksort (SPARK port).
--  Preconditions replace exceptions; only valid call paths are exercised.
--  A'First is always 1; Max_N = 64. Sortedness is proved by SPARK;
--  multiset / permutation equality is checked here. Quicksort is
--  unstable, so tagged equal keys are only checked as a permutation.

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Quicksort; use Quicksort;

procedure Tests
  with SPARK_Mode => Off
is

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

   --  Non-static views (avoid -gnatwa constant-condition warnings).
   function Nat (X : Natural) return Natural is (X);
   function Int (X : Integer) return Integer is (X);
   function Boo (X : Boolean) return Boolean is (X);

   --  Independent insertion-sort reference (strict > when shifting).
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

   --  Multiset equality via sorted copies (permutation check).
   function Is_Permutation (A, B : Element_Array) return Boolean is
      SA : Element_Array := A;
      SB : Element_Array := B;
   begin
      if A'Length /= B'Length then
         return False;
      end if;
      Reference_Sort (SA);
      Reference_Sort (SB);
      return Same (SA, SB);
   end Is_Permutation;

   function Copy_Of (A : Element_Array) return Element_Array is
   begin
      return Element_Array'(A);
   end Copy_Of;

   procedure Expect_Sorted (Src : Element_Array; Label : String) is
      A : Element_Array := Copy_Of (Src);
      R : Element_Array := Copy_Of (Src);
      O : constant Element_Array := Copy_Of (Src);
   begin
      Sort (A);
      Reference_Sort (R);
      Check (Boo (Is_Sorted (A)), Label & " Is_Sorted");
      Check (Same (A, R), Label & " matches reference");
      Check (Is_Permutation (A, O), Label & " permutation");
   end Expect_Sorted;

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

   function Sawtooth (Len : Natural; Period : Positive) return Element_Array is
      A : Element_Array (1 .. Len);
   begin
      for I in A'Range loop
         A (I) := (I - 1) rem Period;
      end loop;
      return A;
   end Sawtooth;

   function Organ_Pipe (Len : Natural) return Element_Array is
      A   : Element_Array (1 .. Len);
      Mid : constant Natural := (Len + 1) / 2;
   begin
      for I in 1 .. Mid loop
         A (I) := I;
      end loop;
      for I in Mid + 1 .. Len loop
         A (I) := Len - I + 1;
      end loop;
      return A;
   end Organ_Pipe;

begin
   Put_Line ("Quicksort (SPARK) tests");
   Put_Line ("=======================");

   ---------------------------------------------------------------------
   Section ("1. Empty and singleton");
   ---------------------------------------------------------------------
   declare
      Empty : Element_Array (1 .. 0);
      One   : Element_Array := [1 => 42];
      Neg   : Element_Array := [1 => -7];
   begin
      Check (In_Bounds (Empty), "empty In_Bounds");
      Check (Boo (Is_Sorted (Empty)), "empty Is_Sorted");
      Sort (Empty);
      Check (Boo (Is_Sorted (Empty)), "empty after Sort");
      Check (In_Bounds (One), "singleton In_Bounds");
      Check (Boo (Is_Sorted (One)), "singleton Is_Sorted");
      Sort (One);
      Check (Int (One (One'First)) = 42, "singleton value preserved");
      Check (Boo (Is_Sorted (One)), "singleton after Sort");
      Sort (Neg);
      Check (Int (Neg (Neg'First)) = -7, "negative singleton preserved");
      Check (Boo (Is_Sorted (Neg)), "negative singleton Is_Sorted");
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
   Expect_Sorted ([5, 5, 5, 1, 5, 5], "mostly equal");
   Expect_Sorted ([2, 2, 2, 2], "four equal");
   Expect_Sorted ([9, 0, 5, 1, 8, 3], "mixed with zero");

   ---------------------------------------------------------------------
   Section ("3. Classic small examples");
   ---------------------------------------------------------------------
   declare
      A : Element_Array := [64, 25, 12, 22, 11];
      O : constant Element_Array := Copy_Of (A);
   begin
      Sort (A);
      Check (Same (A, [11, 12, 22, 25, 64]), "worked example sorts to known");
      Check (Boo (Is_Sorted (A)), "worked example Is_Sorted");
      Check (Is_Permutation (A, O), "worked example permutation");
   end;
   --  Wikipedia-style 8-element example
   Expect_Sorted ([3, 7, 8, 5, 2, 1, 9, 5], "wikipedia 8");
   Expect_Sorted ([1, 2], "two ascending");
   Expect_Sorted ([2, 1], "two descending");
   Expect_Sorted ([1, 1], "two equal");
   Expect_Sorted ([3, 1, 2], "perm 3,1,2");
   Expect_Sorted ([2, 3, 1], "perm 2,3,1");
   Expect_Sorted ([1, 3, 2], "perm 1,3,2");
   Expect_Sorted ([3, 2, 1], "perm 3,2,1");
   Expect_Sorted ([1, 2, 3], "perm 1,2,3");
   Expect_Sorted ([2, 1, 3], "perm 2,1,3");

   ---------------------------------------------------------------------
   Section ("4. Negatives and extreme Integers");
   ---------------------------------------------------------------------
   Expect_Sorted ([-5, -1, -3, -2, -4], "all negatives");
   Expect_Sorted ([Integer'First, 0, Integer'Last], "extremes trio");
   Expect_Sorted
     ([Integer'Last, Integer'First, Integer'First + 1, -1],
      "extremes quartet");
   Expect_Sorted ([-100, 50, -50, 100, 0], "mixed signs");
   Expect_Sorted ([-3, -1, -2], "three negatives");
   Expect_Sorted ([-5, 0, 5, -2, 2], "negatives mixed");
   Expect_Sorted ([-1, -1, -1], "all equal negatives");
   Expect_Sorted ([Integer'First, Integer'Last], "two extremes");
   Expect_Sorted ([Integer'Last, Integer'First], "two extremes reversed");
   Expect_Sorted
     ([Integer'First, Integer'First, Integer'Last, Integer'Last],
      "extreme duplicates");

   ---------------------------------------------------------------------
   Section ("5. In_Bounds / Max_N shape");
   ---------------------------------------------------------------------
   declare
      Cap : Element_Array (1 .. Max_N) := [others => 0];
   begin
      Check (In_Bounds (Cap), "Max_N In_Bounds");
      for I in Cap'Range loop
         Cap (I) := Integer (Max_N + 1 - I);
      end loop;
      Expect_Sorted (Cap, "reverse Max_N");
   end;
   declare
      Empty : Element_Array (1 .. 0);
   begin
      Check (In_Bounds (Empty), "empty still In_Bounds");
      Check (Nat (Empty'Length) = 0, "empty length 0");
   end;
   declare
      Ok : Element_Array (1 .. 3) := [3, 1, 2];
   begin
      Sort (Ok);
      Check (Same (Ok, [1, 2, 3]), "under Max_N still sorts");
   end;

   ---------------------------------------------------------------------
   Section ("6. Random arrays vs reference");
   ---------------------------------------------------------------------
   Expect_Sorted (Random_Array (1, -10, 10), "random n=1");
   Expect_Sorted (Random_Array (2, -100, 100), "random n=2");
   Expect_Sorted (Random_Array (3, -100, 100), "random n=3");
   Expect_Sorted (Random_Array (5, -100, 100), "random n=5");
   Expect_Sorted (Random_Array (7, -1000, 1000), "random n=7");
   Expect_Sorted (Random_Array (8, -100, 100), "random n=8");
   Expect_Sorted (Random_Array (15, -100, 100), "random n=15");
   Expect_Sorted (Random_Array (16, -100, 100), "random n=16");
   Expect_Sorted (Random_Array (20, 0, 9), "random n=20 range 0..9");
   Expect_Sorted (Random_Array (24, -200, 200), "random n=24");
   Expect_Sorted (Random_Array (32, -50, 50), "random n=32");
   Expect_Sorted (Random_Array (48, -200, 200), "random n=48");
   Expect_Sorted (Random_Array (50, -10, 20), "random n=50");
   Expect_Sorted (Random_Array (50, 1, 1), "random all identical n=50");
   Expect_Sorted (Random_Array (64, -20, 20), "random n=64");
   Expect_Sorted (Random_Array (64, 1, 5), "random n=64 range 1..5");
   Expect_Sorted (Random_Array (63, 0, 255), "random n=63 bytes");
   Expect_Sorted (Random_Array (40, 1, 1), "random all-ones");
   Expect_Sorted (Random_Array (16, 0, 0), "random all-zero span");

   ---------------------------------------------------------------------
   Section ("7. Is_Sorted predicate");
   ---------------------------------------------------------------------
   Check (Boo (Is_Sorted ([1, 2, 3, 4])), "ascending true");
   Check (Boo (Is_Sorted ([1, 1, 2, 2])), "nondecreasing true");
   Check (not Boo (Is_Sorted ([1, 3, 2])), "inversion false");
   Check (not Boo (Is_Sorted ([5, 4, 3])), "reverse false");
   Check (Boo (Is_Sorted ([7])), "singleton true");
   Check (Boo (Is_Sorted ([0, 0, 0])), "zeros nondecreasing");
   Check (not Boo (Is_Sorted ([0, 2, 1])), "zero then inversion false");
   Check (Boo (Is_Sorted ([-3, -2, -1, 0])), "negatives ascending");
   Check (not Boo (Is_Sorted ([-1, -3])), "negatives inversion false");
   Check (Boo (Is_Sorted ([Integer'First, Integer'First])),
          "equal extremes sorted");
   Check (not Boo (Is_Sorted ([0, -1])), "descending pair not sorted");
   declare
      E : Element_Array (1 .. 0);
   begin
      Check (Boo (Is_Sorted (E)), "empty true");
   end;

   ---------------------------------------------------------------------
   Section ("8. Adversarial patterns (pivot stress)");
   ---------------------------------------------------------------------
   declare
      A : Element_Array (1 .. 64);
   begin
      for I in A'Range loop
         A (I) := I;
      end loop;
      Expect_Sorted (A, "sorted n=64");
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
      A : Element_Array (1 .. 16);
   begin
      for I in A'Range loop
         A (I) := 17 - I;
      end loop;
      Expect_Sorted (A, "reverse n=16");
   end;
   declare
      A : constant Element_Array (1 .. 64) := [others => 42];
   begin
      Expect_Sorted (A, "all equal n=64");
   end;
   Expect_Sorted (Sawtooth (64, 7), "sawtooth period 7");
   Expect_Sorted (Sawtooth (64, 3), "sawtooth period 3");
   Expect_Sorted (Sawtooth (64, 16), "sawtooth period 16");
   Expect_Sorted (Organ_Pipe (63), "organ pipe n=63");
   Expect_Sorted (Organ_Pipe (64), "organ pipe n=64");
   Expect_Sorted
     ([1, 3, 5, 7, 9, 11, 13, 15, 14, 12, 10, 8, 6, 4, 2, 0],
      "organ half-wave");
   Expect_Sorted
     ([1, 3, 5, 7, 9, 11, 13, 15, 14, 12, 10, 8, 6, 4, 2, 0,
       1, 3, 5, 7, 9, 11, 13, 15, 14, 12, 10, 8, 6, 4, 2, 0],
      "two organ half-waves");
   Expect_Sorted ([16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1],
                  "n=16 reverse");

   ---------------------------------------------------------------------
   Section ("9. Nearly sorted / single inversion");
   ---------------------------------------------------------------------
   Expect_Sorted ([1, 2, 3, 5, 4], "single swap near end");
   Expect_Sorted ([2, 1, 3, 4, 5], "single swap near start");
   Expect_Sorted ([1, 2, 2, 2, 1], "dups with inversion");
   Expect_Sorted ([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 11], "near-sorted n=12");
   Expect_Sorted
     ([20, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19],
      "rotated nearly sorted");
   Expect_Sorted ([1, 2, 3, 5, 4], "almost sorted");
   Expect_Sorted ([1, 10, 2, 20, 3, 30, 4, 40], "two interleaved runs");
   Expect_Sorted ([100, 1, 99, 2, 98, 3, 97, 4, 96, 5], "sawtooth small");
   Expect_Sorted ([1, 2, 4, 8, 16, 32, 64, 128, 256, 3], "powers then disrupt");

   ---------------------------------------------------------------------
   Section ("10. Idempotence");
   ---------------------------------------------------------------------
   declare
      A : Element_Array := [9, 4, 1, 8, 2, 7, 3, 6, 5, 0, -1, 11];
      B : Element_Array (A'Range);
   begin
      Sort (A);
      B := A;
      Sort (A);
      Check (Same (A, B), "Sort twice is idempotent");
      Check (Boo (Is_Sorted (A)), "idempotent result still sorted");
   end;
   declare
      A : Element_Array := Random_Array (48, -999, 999);
      B : Element_Array (A'Range);
   begin
      Sort (A);
      B := A;
      Sort (A);
      Check (Same (A, B), "idempotent on random n=48");
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

   ---------------------------------------------------------------------
   Section ("11. Duplicates and tagged permutation");
   ---------------------------------------------------------------------
   Expect_Sorted ([5, 3, 5, 3, 5, 1, 1], "many dups");
   Expect_Sorted ([7, 7, 7, 1, 1, 9, 9, 9, 9], "runs of equals");
   Expect_Sorted ([4, 4, 4, 2, 2, 2, 4, 2], "two-value multiset");
   Expect_Sorted ([10, 1, 10, 1, 10, 1, 10], "high-low alternating");
   Expect_Sorted ([3, 3, 2, 2, 1, 1], "dup reverse pairs");
   declare
      --  Encode (key, arrival_tag) as key*1000 + tag. Quicksort is
      --  unstable, so only permutation / sortedness are required.
      A : Element_Array := [2001, 1002, 2003, 1004, 2005];
      R : Element_Array := Copy_Of (A);
      O : constant Element_Array := Copy_Of (A);
   begin
      Sort (A);
      Reference_Sort (R);
      Check (Same (A, R), "tagged multiset matches reference");
      Check (Boo (Is_Sorted (A)), "tagged array Is_Sorted");
      Check (Is_Permutation (A, O), "tagged permutation");
      Check (Int (A (1) / 1000) = 1 and then Int (A (2) / 1000) = 1,
             "key-1 tags both in front");
      Check (Int (A (3) / 1000) = 2
             and then Int (A (4) / 1000) = 2
             and then Int (A (5) / 1000) = 2,
             "key-2 tags all in back");
   end;

   ---------------------------------------------------------------------
   Section ("12. Edge patterns and power-of-two sizes");
   ---------------------------------------------------------------------
   Expect_Sorted ([0, 0], "two zeros");
   Expect_Sorted ([-100, 100, -50], "sparse signed");
   Expect_Sorted ([15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1],
                  "reverse 15");
   Expect_Sorted ([1, 3, 5, 7, 9, 2, 4, 6, 8, 10], "odds then evens");
   Expect_Sorted ([8, 0, 8, 0, 8, 0, 8, 0], "sparse high/zero");
   Expect_Sorted ([7], "singleton via Expect");
   Expect_Sorted ([0, 1, 0, 1, 0, 1, 0], "binary keys");
   Expect_Sorted ([5, 4, 3, 2, 1, 0, -1, -2], "strict reverse signed");
   declare
      A : Element_Array (1 .. 10);
   begin
      for I in A'Range loop
         A (I) := I;
      end loop;
      Expect_Sorted (A, "identity 1..10");
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
      Tiny : Element_Array (1 .. 32);
   begin
      for I in Tiny'Range loop
         Tiny (I) := Tiny'Last - I + Tiny'First;
      end loop;
      Sort (Tiny);
      Check (Boo (Is_Sorted (Tiny)), "n=32 reverse under Max_N");
      Check (Tiny (Tiny'First) <= Tiny (Tiny'Last), "n=32 endpoints ordered");
   end;

   New_Line;
   Put_Line
     ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image
      & " FAIL");

   if Fail_Count /= 0 then
      raise Program_Error with "Quicksort tests failed";
   end if;
end Tests;
