--  Standalone test suite for Counting_Sort (SPARK port).
--  Preconditions replace exceptions; only valid call paths are exercised.
--  A'First is always 1; Max_N = 64; Element in 0 .. Max_Key.
--  Sortedness is proved by SPARK; multiset / permutation equality and
--  agreement with a stable insertion-sort reference are checked here.

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Counting_Sort; use Counting_Sort;

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

   function Nat (X : Natural) return Natural is (X);
   function Elt (X : Element) return Element is (X);
   function Boo (X : Boolean) return Boolean is (X);

   procedure Reference_Sort (A : in out Element_Array) is
   begin
      if A'Length <= 1 then
         return;
      end if;
      for I in A'First + 1 .. A'Last loop
         declare
            Key : constant Element := A (I);
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
     (Len : Natural; Lo, Hi : Element) return Element_Array
   is
      Span : constant Positive := Natural (Hi) - Natural (Lo) + 1;
      A    : Element_Array (1 .. Len);
   begin
      for I in A'Range loop
         A (I) := Element (Natural (Lo) + Next_Mod (Span));
      end loop;
      return A;
   end Random_Array;

begin
   Put_Line ("Counting_Sort (SPARK) tests");
   Put_Line ("===========================");

   Section ("1. Empty and singleton");
   declare
      Empty : Element_Array (1 .. 0);
      One   : Element_Array := [1 => 42];
      Zero  : Element_Array := [1 => 0];
   begin
      Check (In_Bounds (Empty), "empty In_Bounds");
      Check (Boo (Is_Sorted (Empty)), "empty Is_Sorted");
      Sort (Empty);
      Check (Boo (Is_Sorted (Empty)), "empty after Sort");
      Check (In_Bounds (One), "singleton In_Bounds");
      Check (Boo (Is_Sorted (One)), "singleton Is_Sorted");
      Sort (One);
      Check (Elt (One (One'First)) = 42, "singleton value preserved");
      Check (Boo (Is_Sorted (One)), "singleton after Sort");
      Sort (Zero);
      Check (Elt (Zero (Zero'First)) = 0, "zero singleton preserved");
      Check (Boo (Is_Sorted (Zero)), "zero singleton Is_Sorted");
   end;

   Section ("2. Small patterns");
   Expect_Sorted ([3, 1, 2], "tiny 3");
   Expect_Sorted ([5, 4, 3, 2, 1], "reverse 5");
   Expect_Sorted ([1, 2, 3, 4, 5], "already sorted");
   Expect_Sorted ([2, 2, 2, 2], "all equal");
   Expect_Sorted ([9, 0, 5, 1, 8, 3], "mixed with zero");
   Expect_Sorted ([3, 7, 4, 9, 5, 2, 6, 1], "wikipedia 8");
   Expect_Sorted ([1, 0], "two swapped with zero");
   Expect_Sorted ([100, 100], "two equal");
   Expect_Sorted ([2, 1, 2, 1, 2, 1], "alternating");
   Expect_Sorted ([1, 2, 3, 5, 4], "almost sorted");
   Expect_Sorted ([9, 8, 7, 6, 5, 4, 3, 2, 1, 0], "reverse 10 with zero");
   Expect_Sorted ([0, 1, 0, 1, 0, 1, 0], "binary keys");
   Expect_Sorted ([0, 0, 0, 0], "all zeros");
   Expect_Sorted ([7], "singleton via Expect");
   Expect_Sorted ([Max_Key, 0, 8, 1], "Max_Key extremes");

   Section ("3. Duplicates and dense small keys");
   Expect_Sorted ([5, 3, 5, 3, 5, 1, 1], "many dups");
   Expect_Sorted ([7, 7, 7, 1, 1, 9, 9, 9, 9], "runs of equals");
   Expect_Sorted ([0, 0, 0, 0, 0, 1, 0], "zeros with one");
   Expect_Sorted ([4, 4, 4, 2, 2, 2, 4, 2], "two-value multiset");
   Expect_Sorted ([10, 1, 10, 1, 10, 1, 10], "high-low alternating");
   Expect_Sorted ([Max_Key, Max_Key, Max_Key], "all Max_Key");
   Expect_Sorted ([0, Max_Key, 0, Max_Key, 0], "min/max alternating");

   Section ("4. Tagged encodings within Max_Key (reference agreement)");
   declare
      A : Element_Array := [21, 12, 23, 14, 25];
      R : Element_Array := Copy_Of (A);
      O : constant Element_Array := Copy_Of (A);
   begin
      Sort (A);
      Reference_Sort (R);
      Check (Same (A, R), "tagged multiset matches reference");
      Check (Boo (Is_Sorted (A)), "tagged array Is_Sorted");
      Check (Is_Permutation (A, O), "tagged permutation");
      Check (Elt (A (1)) = 12 and then Elt (A (2)) = 14,
             "low tags ascending encodings");
      Check (Elt (A (3)) = 21
             and then Elt (A (4)) = 23
             and then Elt (A (5)) = 25,
             "high tags ascending encodings");
   end;
   declare
      A : Element_Array := [51, 52, 53, 14, 15];
   begin
      Sort (A);
      Check (Elt (A (1)) = 14 and then Elt (A (2)) = 15,
             "key-low pair order");
      Check (Elt (A (3)) = 51
             and then Elt (A (4)) = 52
             and then Elt (A (5)) = 53,
             "key-high triple order");
   end;
   declare
      A : Element_Array := [74, 71, 75, 72];
      R : Element_Array := Copy_Of (A);
   begin
      Sort (A);
      Reference_Sort (R);
      Check (Same (A, R), "same-band tags match reference");
      Check (Elt (A (1)) = 71
             and then Elt (A (2)) = 72
             and then Elt (A (3)) = 74
             and then Elt (A (4)) = 75,
             "same-band tags ascending");
   end;

   Section ("5. In_Bounds / Max_N shape");
   declare
      Cap : Element_Array (1 .. Max_N) := [others => 0];
   begin
      Check (In_Bounds (Cap), "Max_N In_Bounds");
      for I in Cap'Range loop
         Cap (I) := Element ((Max_N - I) mod (Max_Key + 1));
      end loop;
      Expect_Sorted (Cap, "pattern Max_N");
   end;
   declare
      Empty : Element_Array (1 .. 0);
   begin
      Check (In_Bounds (Empty), "empty still In_Bounds");
      Check (Nat (Empty'Length) = 0, "empty length 0");
   end;
   declare
      Full_Keys : Element_Array (1 .. 16);
   begin
      for I in Full_Keys'Range loop
         Full_Keys (I) := Element ((16 - I) mod (Max_Key + 1));
      end loop;
      Expect_Sorted (Full_Keys, "spaced keys through Max_Key");
   end;

   Section ("6. Random arrays vs reference");
   Expect_Sorted (Random_Array (20, 0, 9), "random n=20 range 0..9");
   Expect_Sorted (Random_Array (50, 0, 20), "random n=50 range 0..20");
   Expect_Sorted (Random_Array (64, 1, 5), "random n=64 range 1..5");
   Expect_Sorted (Random_Array (64, 0, 3), "random n=64 range 0..3");
   Expect_Sorted (Random_Array (30, 90, 100), "random high band");
   Expect_Sorted (Random_Array (16, 0, 0), "random all-zero span");
   Expect_Sorted (Random_Array (40, 1, 1), "random all-ones");
   Expect_Sorted (Random_Array (25, 0, Max_Key), "random full key domain");
   Expect_Sorted (Random_Array (32, 0, 10), "random n=32 mid");
   Expect_Sorted (Random_Array (48, 200, 255), "random n=48 top band");
   Expect_Sorted (Random_Array (63, 0, Max_Key), "random n=63 domain");
   Expect_Sorted (Random_Array (7, 0, 5), "random n=7 tiny");
   Expect_Sorted (Random_Array (12, 0, 100), "random n=12 mid");

   Section ("7. Is_Sorted predicate");
   Check (Boo (Is_Sorted ([1, 2, 3, 4])), "ascending true");
   Check (Boo (Is_Sorted ([1, 1, 2, 2])), "nondecreasing true");
   Check (not Boo (Is_Sorted ([1, 3, 2])), "inversion false");
   Check (not Boo (Is_Sorted ([5, 4, 3])), "reverse false");
   Check (Boo (Is_Sorted ([7])), "singleton true");
   Check (Boo (Is_Sorted ([0, 0, 0])), "zeros nondecreasing");
   Check (not Boo (Is_Sorted ([0, 2, 1])), "zero then inversion false");
   Check (Boo (Is_Sorted ([0, 8, Max_Key])), "min mid max ascending");
   Check (not Boo (Is_Sorted ([Max_Key, 0])), "max then min false");
   declare
      E : Element_Array (1 .. 0);
   begin
      Check (Boo (Is_Sorted (E)), "empty true");
   end;

   Section ("8. Edge patterns and power-of-two sizes");
   Expect_Sorted ([1, 2], "two ascending");
   Expect_Sorted ([2, 1], "two descending");
   Expect_Sorted ([0, 0], "two zeros");
   Expect_Sorted ([0, Max_Key], "min max pair");
   Expect_Sorted ([Max_Key, 0], "max min pair");
   Expect_Sorted ([15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1],
                  "reverse 15");
   Expect_Sorted ([1, 3, 5, 7, 9, 2, 4, 6, 8, 10], "odds then evens");
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
         A (I) := Element (11 - I);
      end loop;
      Expect_Sorted (A, "countdown 10..1");
   end;
   declare
      A : Element_Array (1 .. 64);
   begin
      for I in A'Range loop
         A (I) := Element (I rem (Max_Key + 1));
      end loop;
      Expect_Sorted (A, "already sorted n=64");
   end;
   declare
      A : Element_Array (1 .. 32);
   begin
      for I in A'Range loop
         A (I) := Element (33 - I);
      end loop;
      Expect_Sorted (A, "reverse n=32");
   end;
   declare
      A : Element_Array (1 .. 17);
   begin
      for I in A'Range loop
         A (I) := Element ((18 - I) mod (Max_Key + 1));
      end loop;
      Expect_Sorted (A, "odd length reverse 17");
   end;
   declare
      A : Element_Array (1 .. 50);
   begin
      for I in A'Range loop
         A (I) := Element (I rem (Max_Key + 1));
      end loop;
      A (25) := 1;
      A (1) := 25;
      Expect_Sorted (A, "nearly sorted n=50 one swap");
   end;

   Section ("9. Idempotence");
   declare
      A : Element_Array := [9, 3, 7, 1, 5, 0, 4, 2];
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

   Section ("10. Full domain edges");
   Expect_Sorted ([255, 254, 253, 0, 1, 2], "top and bottom");
   Expect_Sorted ([3, 3, 2, 2, 1, 1], "dup reverse pairs");
   Expect_Sorted ([1, 10, 2, 20, 3, 30, 4, 40], "two interleaved runs");
   Expect_Sorted
     ([100, 1, 99, 2, 98, 3, 97, 4, 96, 5], "sawtooth");
   Expect_Sorted
     ([1, 2, 4, 8, 16, 32, 64, 128, 255, 3], "powers then disrupt");
   declare
      A : Element_Array (1 .. 64);
   begin
      for I in A'Range loop
         A (I) := Element ((65 - I) rem (Max_Key + 1));
      end loop;
      Expect_Sorted (A, "reverse-ish n=64");
   end;
   Expect_Sorted ([0, Max_Key], "exact Max_Key span pair");
   Expect_Sorted ([Max_Key, 0, Max_Key, 0], "Max_Key ping-pong");

   New_Line;
   Put_Line
     ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image
      & " FAIL");

   if Fail_Count /= 0 then
      raise Program_Error with "Counting_Sort tests failed";
   end if;
end Tests;
