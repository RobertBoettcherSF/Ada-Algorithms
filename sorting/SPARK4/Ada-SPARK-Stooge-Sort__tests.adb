--  Standalone test suite for Stooge_Sort (SPARK port).
--  CRITICAL: keep n tiny — Stooge sort is O(n^2.709).
--  Preconditions replace exceptions; only valid call paths are exercised.
--  A'First is always 1; Max_N = 24. Sortedness is proved by SPARK;
--  multiset / permutation equality is checked here.

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Stooge_Sort; use Stooge_Sort;

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
   Put_Line ("Stooge_Sort (SPARK) tests");
   Put_Line ("=========================");

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
   Section ("2. Small patterns (n <= 12)");
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
   Expect_Sorted ([9, 8, 7, 6, 5, 4, 3, 2, 1, 0], "reverse 10 with zero");
   Expect_Sorted ([0, 1, 0, 1, 0, 1, 0], "binary keys");
   Expect_Sorted ([0, 0, 0, 0], "all zeros");
   Expect_Sorted ([7], "singleton via Expect");
   Expect_Sorted ([6, 5, 4, 3, 2, 1], "reverse 6");
   Expect_Sorted ([8, 7, 6, 5, 4, 3, 2, 1], "reverse 8");
   Expect_Sorted ([1, 3, 5, 7, 9, 2, 4, 6], "odds then evens 8");
   Expect_Sorted ([4, 1, 3, 2], "tiny 4 permutation");
   Expect_Sorted ([5, 1, 4, 2, 3], "tiny 5 permutation");

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
   Expect_Sorted ([-2, -2, 0, 0, 2, 2], "paired signed");

   ---------------------------------------------------------------------
   Section ("4. In_Bounds / Max_N shape (A'First = 1)");
   ---------------------------------------------------------------------
   declare
      Cap : Element_Array (1 .. 12) := [others => 0];
   begin
      Check (In_Bounds (Cap), "n=12 In_Bounds");
      for I in Cap'Range loop
         Cap (I) := Integer (13 - I);
      end loop;
      Expect_Sorted (Cap, "reverse n=12");
   end;
   declare
      Empty : Element_Array (1 .. 0);
   begin
      Check (In_Bounds (Empty), "empty still In_Bounds");
      Check (Nat (Empty'Length) = 0, "empty length 0");
   end;
   declare
      Ok : Element_Array (1 .. 12) := [others => 3];
   begin
      Sort (Ok);
      Check (Boo (Is_Sorted (Ok)), "n=12 all equal sorts (under Max_N)");
      Check (In_Bounds (Ok), "n=12 still In_Bounds");
   end;

   ---------------------------------------------------------------------
   Section ("5. Random arrays vs reference (tiny n only)");
   ---------------------------------------------------------------------
   Expect_Sorted (Random_Array (8, 0, 9), "random n=8 range 0..9");
   Expect_Sorted (Random_Array (10, -10, 20), "random n=10 signed");
   Expect_Sorted (Random_Array (12, 1, 5), "random n=12 range 1..5");
   Expect_Sorted (Random_Array (14, -3, 3), "random n=14 range -3..3");
   Expect_Sorted (Random_Array (16, 0, 0), "random n=16 all-zero span");
   Expect_Sorted (Random_Array (7, -5, 5), "random n=7 tiny");
   Expect_Sorted (Random_Array (9, 90, 100), "random n=9 high band");
   Expect_Sorted (Random_Array (11, -100, 100), "random n=11 wide");
   Expect_Sorted (Random_Array (13, -2, 2), "random n=13 narrow");
   Expect_Sorted (Random_Array (15, 1, 3), "random n=15 three values");

   ---------------------------------------------------------------------
   Section ("6. Cautious n=16 reverse (not larger)");
   ---------------------------------------------------------------------
   --  Stooge is O(n^2.709); n=16 reverse is still interactive. Never n>>16.
   Expect_Sorted
     ([16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1],
      "reverse 16");
   Expect_Sorted (Random_Array (16, -5, 5), "random n=16 range -5..5");

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
   Check (Boo (Is_Sorted ([1, 2])), "pair ascending true");
   Check (not Boo (Is_Sorted ([2, 1])), "pair descending false");
   declare
      E : Element_Array (1 .. 0);
   begin
      Check (Boo (Is_Sorted (E)), "empty true");
   end;

   ---------------------------------------------------------------------
   Section ("8. Edge patterns");
   ---------------------------------------------------------------------
   Expect_Sorted ([1, 2], "two ascending");
   Expect_Sorted ([2, 1], "two descending");
   Expect_Sorted ([0, 0], "two zeros");
   Expect_Sorted ([-100, 100, -50], "sparse signed");
   Expect_Sorted ([12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1], "reverse 12");
   Expect_Sorted ([1, 3, 5, 7, 9, 2, 4, 6, 8, 10], "odds then evens 10");
   Expect_Sorted ([8, 0, 8, 0, 8, 0, 8, 0], "sparse high/zero");
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
   Expect_Sorted ([Integer'First / 4, 0, Integer'Last / 4, -1, 1],
                  "large magnitude ints");
   Expect_Sorted ([3, 2, 1], "reverse 3");
   Expect_Sorted ([4, 3, 2, 1], "reverse 4");

   ---------------------------------------------------------------------
   Section ("9. Idempotence");
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
         Check (Boo (Is_Sorted (A)), "idempotent still sorted");
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
   declare
      A : Element_Array := [5, 1, 4, 2, 3, 0, -1];
   begin
      Sort (A);
      declare
         B : constant Element_Array := Copy_Of (A);
      begin
         Sort (A);
         Check (Same (A, B), "idempotent after mixed-7");
         Check (Boo (Is_Sorted (A)), "idempotent mixed-7 still sorted");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("10. Contract helpers");
   ---------------------------------------------------------------------
   Check (In_Bounds ([1 => 1, 2 => 2]), "tiny In_Bounds");
   Check (Nat (Max_N) = 24, "Max_N is 24");
   declare
      A : Element_Array (1 .. Max_N) := [others => 0];
   begin
      Check (In_Bounds (A), "Max_N length In_Bounds");
      --  Do NOT Sort reverse Max_N — O(n^2.709) would hang demos.
      Sort (A);
      Check (Boo (Is_Sorted (A)), "Max_N all-zero sorts");
   end;

   New_Line;
   Put_Line
     ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image
      & " FAIL");

   if Fail_Count /= 0 then
      raise Program_Error with "Stooge_Sort tests failed";
   end if;
end Tests;
