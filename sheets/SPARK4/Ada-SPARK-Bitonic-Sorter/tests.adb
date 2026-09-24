--  Standalone test suite for Bitonic_Sorter (SPARK port).
--  Preconditions replace exceptions; only valid call paths are exercised.
--  A'First is always 1; Max_N = 64. Sortedness is proved by SPARK;
--  multiset / permutation equality is checked here.

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Bitonic_Sorter; use Bitonic_Sorter;

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
   Put_Line ("Bitonic_Sorter (SPARK) tests");
   Put_Line ("============================");

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
   Section ("2. Powers of two");
   ---------------------------------------------------------------------
   Expect_Sorted ([3, 1], "n=2 reverse");
   Expect_Sorted ([1, 2], "n=2 sorted");
   Expect_Sorted ([4, 3, 2, 1], "n=4 reverse");
   Expect_Sorted ([1, 3, 2, 4], "n=4 mixed");
   Expect_Sorted ([8, 7, 6, 5, 4, 3, 2, 1], "n=8 reverse");
   Expect_Sorted ([5, 1, 8, 3, 7, 2, 6, 4], "n=8 shuffled");
   Expect_Sorted
     ([16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1],
      "n=16 reverse");
   Expect_Sorted (Random_Array (32, -50, 50), "n=32 random");
   Expect_Sorted (Random_Array (64, -100, 100), "n=64 random");
   Expect_Sorted ([1, 2, 3, 4, 5, 6, 7, 8], "already sorted n=8");
   Expect_Sorted ([1, 1, 1, 1], "all equal n=4");
   Expect_Sorted ([5, 5, 3, 3, 5, 1, 1, 3], "duplicates n=8");

   ---------------------------------------------------------------------
   Section ("3. Padding (non-power-of-two lengths)");
   ---------------------------------------------------------------------
   Expect_Sorted ([3, 1, 2], "n=3 padded");
   Expect_Sorted ([5, 4, 3, 2, 1], "n=5 reverse padded");
   Expect_Sorted ([9, 1, 8, 2, 7, 3, 6], "n=7 shuffled padded");
   Expect_Sorted
     ([10, 9, 8, 7, 6, 5, 4, 3, 2], "n=9 reverse padded");
   Expect_Sorted (Random_Array (12, -20, 20), "n=12 random padded");
   Expect_Sorted (Random_Array (15, 0, 100), "n=15 random padded");
   Expect_Sorted ([1, 2, 3], "n=3 already sorted padded");
   Expect_Sorted
     ([Integer'Last, 1, 0], "n=3 with Integer'Last data");
   Expect_Sorted
     ([5, Integer'Last, 3, Integer'Last, 1],
      "n=5 with Integer'Last data");
   Expect_Sorted (Random_Array (6, -50, 50), "random n=6 padded");
   Expect_Sorted (Random_Array (10, -50, 50), "random n=10 padded");
   Expect_Sorted (Random_Array (24, -50, 50), "random n=24 padded");
   Expect_Sorted (Random_Array (33, -10, 10), "random n=33 padded");
   Expect_Sorted (Random_Array (63, 0, 255), "random n=63 padded");

   ---------------------------------------------------------------------
   Section ("4. Negatives and duplicates");
   ---------------------------------------------------------------------
   Expect_Sorted ([-3, -1, 0, 2], "negatives sorted n=4");
   Expect_Sorted ([0, -5, 10, -5], "negatives mixed n=4");
   Expect_Sorted ([-3, -1, -2], "three negatives");
   Expect_Sorted ([-5, 0, 5, -2, 2], "negatives mixed 5");
   Expect_Sorted ([-1, -1, -1], "all equal negatives");
   Expect_Sorted ([5, 3, 5, 3, 5, 1, 1], "many dups");
   Expect_Sorted ([7, 7, 7, 1, 1, 9, 9], "runs of equals");
   Expect_Sorted ([-10, 10, -5, 5, 0], "symmetric around zero");
   Expect_Sorted ([4, 4, 4, 2, 2, 2, 4, 2], "two-value multiset");
   Expect_Sorted ([10, 1, 10, 1, 10, 1], "high-low alternating");

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
      Ok : Element_Array (1 .. Max_N) := [others => 1];
   begin
      Sort (Ok);
      Check (Boo (Is_Sorted (Ok)), "n = Max_N all equal sorts");
      Check (In_Bounds (Ok), "n = Max_N still In_Bounds");
   end;
   Check (Nat (Max_N) = 64, "Max_N is 64");

   ---------------------------------------------------------------------
   Section ("6. Random arrays vs reference");
   ---------------------------------------------------------------------
   Expect_Sorted (Random_Array (20, 0, 9), "random n=20 range 0..9");
   Expect_Sorted (Random_Array (50, -10, 20), "random n=50 range -10..20");
   Expect_Sorted (Random_Array (64, 1, 5), "random n=64 range 1..5");
   Expect_Sorted (Random_Array (64, -3, 3), "random n=64 range -3..3");
   Expect_Sorted (Random_Array (30, 90, 100), "random high band");
   Expect_Sorted (Random_Array (16, 0, 0), "random all-zero span");
   Expect_Sorted (Random_Array (40, 1, 1), "random all-ones");
   Expect_Sorted (Random_Array (25, -100, 100), "random wide signed");
   Expect_Sorted (Random_Array (7, -5, 5), "random n=7 tiny");
   Expect_Sorted (Random_Array (3, 0, 10), "random n=3");
   Expect_Sorted (Random_Array (2, -1000, 1000), "random n=2");
   Expect_Sorted (Random_Array (4, -1000, 1000), "random n=4");
   Expect_Sorted (Random_Array (8, -1000, 1000), "random n=8");

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
   Check (Boo (Is_Sorted ([-5, -5, -5])), "equal negatives true");
   declare
      E : Element_Array (1 .. 0);
   begin
      Check (Boo (Is_Sorted (E)), "empty true");
   end;

   ---------------------------------------------------------------------
   Section ("8. Edge lengths and structure");
   ---------------------------------------------------------------------
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
      A : Element_Array (1 .. 50);
   begin
      for I in A'Range loop
         A (I) := I;
      end loop;
      A (25) := 1;
      A (1) := 25;
      Expect_Sorted (A, "nearly sorted n=50 one swap");
   end;
   Expect_Sorted ([Integer'First, Integer'Last, 0, -1],
                  "extreme Integer values n=4");
   Expect_Sorted ([Integer'First, Integer'First + 1, -1],
                  "extreme n=3 padded");
   Expect_Sorted ([Integer'Last, Integer'First], "Last then First");
   Expect_Sorted ([0], "zero singleton via Expect");
   Expect_Sorted ([-42], "neg singleton via Expect");
   Expect_Sorted ([7], "singleton via Expect");

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
   Section ("10. Bitonic-friendly patterns");
   ---------------------------------------------------------------------
   Expect_Sorted ([1, 3, 5, 7, 8, 6, 4, 2], "bitonic rise-fall n=8");
   Expect_Sorted ([1, 2, 4, 8, 16, 32, 64, 3], "powers then disrupt");
   Expect_Sorted ([8, 0, 8, 0, 8, 0, 8, 0], "sparse high/zero");
   Expect_Sorted ([100, 1, 99, 2, 98, 3, 97, 4], "sawtooth n=8");
   Expect_Sorted ([1, 10, 2, 20, 3, 30, 4, 40], "two interleaved runs");
   Expect_Sorted ([15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1],
                  "reverse 15 padded");

   New_Line;
   Put_Line
     ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image
      & " FAIL");

   if Fail_Count /= 0 then
      raise Program_Error with "Bitonic_Sorter tests failed";
   end if;
end Tests;
