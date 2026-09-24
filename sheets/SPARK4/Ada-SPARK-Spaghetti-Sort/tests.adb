--  Standalone test suite for Spaghetti_Sort (SPARK port).
--  Preconditions replace exceptions; only valid call paths are exercised.
--  A'First is always 1; Max_N = 64; keys in 0 .. Max_Key = 64.
--  Sortedness is proved by SPARK; multiset / permutation equality is
--  checked here. Only height-bin Sort is exported (Sort_Extraction is a
--  non-SPARK sibling feature).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Spaghetti_Sort; use Spaghetti_Sort;

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
      Check (In_Bounds (A), Label & " In_Bounds");
      Check (Keys_Ok (A), Label & " Keys_Ok");
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

   --  Random array with keys in Lo .. Hi ⊆ 0 .. Max_Key.
   function Random_Array
     (Len : Natural; Lo, Hi : Natural) return Element_Array
   is
      Span : constant Positive := Hi - Lo + 1;
      A    : Element_Array (1 .. Len);
   begin
      for I in A'Range loop
         A (I) := Integer (Lo + Next_Mod (Span));
      end loop;
      return A;
   end Random_Array;

begin
   Put_Line ("Spaghetti_Sort (SPARK) tests");
   Put_Line ("============================");

   ---------------------------------------------------------------------
   Section ("1. Empty and singleton");
   ---------------------------------------------------------------------
   declare
      Empty : Element_Array (1 .. 0);
      One   : Element_Array := [1 => 42];
      Zero  : Element_Array := [1 => 0];
   begin
      Check (In_Bounds (Empty), "empty In_Bounds");
      Check (Keys_Ok (Empty), "empty Keys_Ok");
      Check (Boo (Is_Sorted (Empty)), "empty Is_Sorted");
      Sort (Empty);
      Check (Boo (Is_Sorted (Empty)), "empty after Sort");
      Check (In_Bounds (One), "singleton In_Bounds");
      Check (Keys_Ok (One), "singleton Keys_Ok");
      Check (Boo (Is_Sorted (One)), "singleton Is_Sorted");
      Sort (One);
      Check (Int (One (One'First)) = 42, "singleton value preserved");
      Check (Boo (Is_Sorted (One)), "singleton after Sort");
      Sort (Zero);
      Check (Int (Zero (Zero'First)) = 0, "zero singleton preserved");
      Check (Boo (Is_Sorted (Zero)), "zero singleton Is_Sorted");
   end;
   Expect_Sorted ([0], "zero singleton via Expect");
   Expect_Sorted ([Max_Key], "Max_Key singleton via Expect");

   ---------------------------------------------------------------------
   Section ("2. Small height-bin patterns");
   ---------------------------------------------------------------------
   Expect_Sorted ([3, 1, 2], "tiny 3");
   Expect_Sorted ([5, 4, 3, 2, 1], "reverse 5");
   Expect_Sorted ([1, 2, 3, 4, 5], "already sorted");
   Expect_Sorted ([2, 2, 2, 2], "all equal");
   Expect_Sorted ([9, 0, 5, 1, 8, 3], "mixed with zero");
   Expect_Sorted ([3, 2, 4, 2], "wiki-ish heights");
   Expect_Sorted ([1, 0], "two swapped with zero");
   Expect_Sorted ([Max_Key, Max_Key], "two equal Max_Key");
   Expect_Sorted ([2, 1, 2, 1, 2, 1], "alternating");
   Expect_Sorted ([1, 2, 3, 5, 4], "almost sorted");
   Expect_Sorted ([9, 8, 7, 6, 5, 4, 3, 2, 1, 0], "reverse 10 with zero");
   Expect_Sorted ([0, 1, 0, 1, 0, 1, 0], "binary keys");
   Expect_Sorted ([0, 0, 0, 0], "all zeros");
   Expect_Sorted ([Max_Key, 0, 8, 1], "Max_Key extremes");

   ---------------------------------------------------------------------
   Section ("3. Duplicates and runs (stable multiset)");
   ---------------------------------------------------------------------
   Expect_Sorted ([5, 3, 5, 3, 5, 1, 1], "many dups");
   Expect_Sorted ([7, 7, 7, 1, 1, 9, 9, 9, 9], "runs of equals");
   Expect_Sorted ([0, 0, 0, 0, 0, 1, 0], "zeros with one");
   Expect_Sorted ([4, 4, 4, 2, 2, 2, 4, 2], "two-value multiset");
   Expect_Sorted ([10, 1, 10, 1, 10, 1, 10], "high-low alternating");
   Expect_Sorted ([Max_Key, Max_Key, Max_Key], "all Max_Key");
   Expect_Sorted ([0, Max_Key, 0, Max_Key, 0], "min/max alternating");

   ---------------------------------------------------------------------
   Section ("4. In_Bounds / Keys_Ok / Max_N shape");
   ---------------------------------------------------------------------
   declare
      Cap : Element_Array (1 .. Max_N) := [others => 0];
   begin
      Check (In_Bounds (Cap), "Max_N In_Bounds");
      Check (Keys_Ok (Cap), "Max_N Keys_Ok");
      for I in Cap'Range loop
         Cap (I) := Integer ((Max_N - I) mod (Max_Key + 1));
      end loop;
      Expect_Sorted (Cap, "pattern Max_N");
   end;
   declare
      Empty : Element_Array (1 .. 0);
   begin
      Check (In_Bounds (Empty), "empty still In_Bounds");
      Check (Int (Empty'Length) = 0, "empty length 0");
   end;
   declare
      Ok : Element_Array := [0, Max_Key];
   begin
      Check (Keys_Ok (Ok), "exact Max_Key Keys_Ok");
      Sort (Ok);
      Check (Boo (Is_Sorted (Ok)), "exact Max_Key sorts");
      Check (Int (Ok (Ok'First)) = 0 and then Int (Ok (Ok'Last)) = Max_Key,
             "exact Max_Key placement");
   end;
   declare
      Bad : constant Element_Array := [1, Max_Key + 1];
   begin
      Check (In_Bounds (Bad), "oversize key still In_Bounds");
      Check (not Keys_Ok (Bad), "oversize key not Keys_Ok");
   end;
   declare
      Neg : constant Element_Array := [-1, 3];
   begin
      Check (In_Bounds (Neg), "negative key still In_Bounds");
      Check (not Keys_Ok (Neg), "negative key not Keys_Ok");
   end;
   declare
      Bad2 : constant Element_Array := [Max_Key + 50];
   begin
      Check (not Keys_Ok (Bad2), "singleton oversize not Keys_Ok");
   end;

   ---------------------------------------------------------------------
   Section ("5. Random arrays vs reference");
   ---------------------------------------------------------------------
   Expect_Sorted (Random_Array (20, 0, 9), "random n=20 range 0..9");
   Expect_Sorted (Random_Array (50, 0, 20), "random n=50 range 0..20");
   Expect_Sorted (Random_Array (64, 1, 5), "random n=64 range 1..5");
   Expect_Sorted (Random_Array (64, 0, 3), "random n=64 range 0..3");
   Expect_Sorted (Random_Array (30, 50, 64), "random high band");
   Expect_Sorted (Random_Array (16, 0, 0), "random all-zero span");
   Expect_Sorted (Random_Array (40, 1, 1), "random all-ones");
   Expect_Sorted (Random_Array (25, 0, Max_Key / 4),
                  "random modest Max_Key/4");
   Expect_Sorted (Random_Array (64, 0, Max_Key), "random full domain");

   ---------------------------------------------------------------------
   Section ("6. Is_Sorted predicate");
   ---------------------------------------------------------------------
   Check (Boo (Is_Sorted ([1, 2, 3, 4])), "ascending true");
   Check (Boo (Is_Sorted ([1, 1, 2, 2])), "nondecreasing true");
   Check (not Boo (Is_Sorted ([1, 3, 2])), "inversion false");
   Check (not Boo (Is_Sorted ([5, 4, 3])), "reverse false");
   Check (Boo (Is_Sorted ([7])), "singleton true");
   Check (Boo (Is_Sorted ([0, 0, 0])), "zeros nondecreasing");
   Check (not Boo (Is_Sorted ([0, 2, 1])), "zero then inversion false");
   declare
      E : Element_Array (1 .. 0);
   begin
      Check (Boo (Is_Sorted (E)), "empty true");
   end;

   ---------------------------------------------------------------------
   Section ("7. Height-bin emit / Dewdney classroom");
   ---------------------------------------------------------------------
   Expect_Sorted ([1, 2], "two ascending");
   Expect_Sorted ([2, 1], "two descending");
   Expect_Sorted ([0, 0], "two zeros");
   Expect_Sorted ([Max_Key / 2, 1, Max_Key / 2], "half-max dups");
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
         A (I) := 11 - I;
      end loop;
      Expect_Sorted (A, "countdown 10..1");
   end;
   --  Height-bin emit: [3,2,4,2] → counts → [2,2,3,4]
   declare
      A : Element_Array := [3, 2, 4, 2];
   begin
      Sort (A);
      Check (Int (A (1)) = 2 and then Int (A (2)) = 2
             and then Int (A (3)) = 3 and then Int (A (4)) = 4,
             "height-bin [3,2,4,2] → [2,2,3,4]");
   end;
   --  Dense rod lengths covering many bins
   declare
      A : Element_Array (1 .. 20);
   begin
      for I in A'Range loop
         A (I) := Integer ((I * 3) rem (Max_Key + 1));
      end loop;
      Expect_Sorted (A, "dense bin cover rem");
   end;

   ---------------------------------------------------------------------
   Section ("8. Idempotence");
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
         Check (Boo (Is_Sorted (A)), "idempotent still sorted");
         Check (Is_Permutation (A, B), "idempotent permutation");
      end;
   end;

   New_Line;
   Put_Line
     ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image
      & " FAIL");

   if Fail_Count /= 0 then
      raise Program_Error with "Spaghetti_Sort tests failed";
   end if;
end Tests;
