--  Standalone test suite for Smoothsort (SPARK port).
--  Preconditions replace exceptions; only valid call paths are exercised.
--  A'First is always 1; Max_N = 64. Sortedness is proved by SPARK;
--  multiset / permutation equality is checked here. Smoothsort is
--  unstable, so equal keys are only checked as a permutation.

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Smoothsort; use Smoothsort;

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

   function Sorted_Array (Len : Natural; Start : Integer := 1)
     return Element_Array
   is
      A : Element_Array (1 .. Len);
   begin
      for I in A'Range loop
         A (I) := Start + Integer (I - A'First);
      end loop;
      return A;
   end Sorted_Array;

   function Reverse_Array (Len : Natural) return Element_Array is
      A : Element_Array (1 .. Len);
   begin
      for I in A'Range loop
         A (I) := Integer (Len) - Integer (I - A'First);
      end loop;
      return A;
   end Reverse_Array;

begin
   Put_Line ("Smoothsort (SPARK) tests");
   Put_Line ("========================");

   ---------------------------------------------------------------------
   Section ("1. Leonardo numbers");
   ---------------------------------------------------------------------
   Check (Nat (Leonardo (0)) = 1, "L(0) = 1");
   Check (Nat (Leonardo (1)) = 1, "L(1) = 1");
   Check (Nat (Leonardo (2)) = 3, "L(2) = 3");
   Check (Nat (Leonardo (3)) = 5, "L(3) = 5");
   Check (Nat (Leonardo (4)) = 9, "L(4) = 9");
   Check (Nat (Leonardo (5)) = 15, "L(5) = 15");
   Check (Nat (Leonardo (6)) = 25, "L(6) = 25");
   Check (Nat (Leonardo (7)) = 41, "L(7) = 41");
   Check (Nat (Leonardo (8)) = 67, "L(8) = 67");
   Check (Nat (Leonardo (2)) = Leonardo (1) + Leonardo (0) + 1,
          "recurrence L(2)=L(1)+L(0)+1");
   Check (Nat (Leonardo (7)) = Leonardo (6) + Leonardo (5) + 1,
          "recurrence L(7)=L(6)+L(5)+1");
   Check (Nat (Max_Leonardo_Order) = 8, "Max_Leonardo_Order = 8");

   ---------------------------------------------------------------------
   Section ("2. Empty and singleton");
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
      Check (Int (One (1)) = 42, "singleton value preserved");
      Check (Boo (Is_Sorted (One)), "singleton after Sort");
      Sort (Neg);
      Check (Int (Neg (1)) = -7, "negative singleton preserved");
   end;

   ---------------------------------------------------------------------
   Section ("3. Already sorted / reverse / duplicates");
   ---------------------------------------------------------------------
   Expect_Sorted ([1, 2, 3, 4, 5], "already sorted");
   Expect_Sorted ([5, 4, 3, 2, 1], "fully reversed");
   Expect_Sorted ([3, 1, 4, 1, 5, 9, 2, 6], "pi digits");
   Expect_Sorted ([7, 7, 7, 7], "all equal");
   Expect_Sorted ([2, 1, 2, 1, 2], "alternating duplicates");
   Expect_Sorted ([0, -1, 0, -1], "zeros and negatives");

   ---------------------------------------------------------------------
   Section ("4. Leonardo-sized lengths");
   ---------------------------------------------------------------------
   Expect_Sorted (Sorted_Array (3), "sorted n=3 = L(2)");
   Expect_Sorted (Sorted_Array (5), "sorted n=5 = L(3)");
   Expect_Sorted (Sorted_Array (9), "sorted n=9 = L(4)");
   Expect_Sorted (Sorted_Array (15), "sorted n=15 = L(5)");
   Expect_Sorted (Sorted_Array (25), "sorted n=25 = L(6)");
   Expect_Sorted (Sorted_Array (41), "sorted n=41 = L(7)");
   Expect_Sorted (Reverse_Array (3), "reverse n=3");
   Expect_Sorted (Reverse_Array (5), "reverse n=5");
   Expect_Sorted (Reverse_Array (15), "reverse n=15");
   Expect_Sorted (Reverse_Array (41), "reverse n=41");

   ---------------------------------------------------------------------
   Section ("5. Classic worked example");
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

   ---------------------------------------------------------------------
   Section ("6. Two-element and small permutations");
   ---------------------------------------------------------------------
   Expect_Sorted ([1, 2], "two ascending");
   Expect_Sorted ([2, 1], "two descending");
   Expect_Sorted ([1, 1], "two equal");
   Expect_Sorted ([3, 1, 2], "perm 3,1,2");
   Expect_Sorted ([2, 3, 1], "perm 2,3,1");
   Expect_Sorted ([1, 3, 2], "perm 1,3,2");

   ---------------------------------------------------------------------
   Section ("7. Negatives and extreme Integers");
   ---------------------------------------------------------------------
   Expect_Sorted ([-5, -1, -3, -2, -4], "all negatives");
   Expect_Sorted ([Integer'First, 0, Integer'Last], "extremes trio");
   Expect_Sorted
     ([Integer'Last, Integer'First, Integer'First + 1, -1],
      "extremes quartet");

   ---------------------------------------------------------------------
   Section ("8. Is_Sorted / In_Bounds predicates");
   ---------------------------------------------------------------------
   Check (Boo (Is_Sorted ([1, 2, 2, 3])), "nondecreasing true");
   Check (not Boo (Is_Sorted ([1, 3, 2])), "unsorted ascending false");
   Check (Boo (Is_Sorted ([Integer'First, Integer'First])),
          "equal extremes sorted");
   Check (not Boo (Is_Sorted ([0, -1])), "descending pair not sorted");
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
   Expect_Sorted (Random_Array (50, 0, 10), "random n=50 many dups");
   Expect_Sorted (Random_Array (40, 1, 1), "random all identical");
   Expect_Sorted (Random_Array (63, -100, 100), "random n=63");
   Expect_Sorted (Random_Array (7, -5, 5), "random n=7");
   Expect_Sorted (Random_Array (12, -1000, 1000), "random n=12");

   ---------------------------------------------------------------------
   Section ("10. Idempotence and patterned");
   ---------------------------------------------------------------------
   declare
      A : Element_Array := [9, 4, 1, 8, 2, 7, 3];
      B : Element_Array (A'Range);
   begin
      Sort (A);
      B := A;
      Sort (A);
      Check (Same (A, B), "Sort twice is idempotent");
      Check (Boo (Is_Sorted (A)), "idempotent result still sorted");
   end;
   Expect_Sorted ([1, 2, 3, 5, 4], "single swap near end");
   Expect_Sorted ([2, 1, 3, 4, 5], "single swap near start");
   Expect_Sorted ([1, 2, 2, 2, 1], "dups with inversion");
   Expect_Sorted ([100, 1, 99, 2, 98, 3, 97, 4, 96, 5], "sawtooth");
   Expect_Sorted ([1, 3, 5, 7, 9, 2, 4, 6, 8, 10], "two interleaved runs");
   Expect_Sorted (Reverse_Array (32), "reverse n=32");
   Expect_Sorted (Reverse_Array (17), "odd length reverse 17");
   Expect_Sorted (Reverse_Array (64), "reverse n=64");
   Expect_Sorted (Sorted_Array (64), "already sorted n=64");

   New_Line;
   Put_Line
     ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image
      & " FAIL");

   if Fail_Count /= 0 then
      raise Program_Error with "Smoothsort tests failed";
   end if;
end Tests;
