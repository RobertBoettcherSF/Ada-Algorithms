--  Standalone test suite for Samplesort (SPARK port).
--  Preconditions replace exceptions; only valid call paths are exercised.
--  A'First is always 1; Max_N = 64; Num_Buckets = 8. Sortedness is proved
--  by SPARK; multiset / permutation equality is checked here.

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Samplesort; use Samplesort;

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
      Span_LL : constant Long_Long_Integer :=
        Long_Long_Integer (Hi) - Long_Long_Integer (Lo) + 1;
      Span    : constant Positive := Positive (Span_LL);
      A       : Element_Array (1 .. Len);
   begin
      for I in A'Range loop
         A (I) := Lo + Integer (Next_Mod (Span));
      end loop;
      return A;
   end Random_Array;

   function Uniform_Ish (Len : Natural) return Element_Array is
      A : Element_Array (1 .. Len);
   begin
      for I in A'Range loop
         A (I) := Integer (Next_Mod (Len)) + 1;
      end loop;
      return A;
   end Uniform_Ish;

   function Clustered
     (Len : Natural; Clusters : Positive; Lo, Hi : Integer)
      return Element_Array
   is
      A     : Element_Array (1 .. Len);
      Span  : constant Long_Long_Integer :=
        Long_Long_Integer (Hi) - Long_Long_Integer (Lo);
      Width : constant Integer :=
        Integer'Max (1, Integer (Span / Long_Long_Integer (Clusters * 8)));
   begin
      for I in A'Range loop
         declare
            C      : constant Natural := Next_Mod (Clusters);
            Center : constant Integer :=
              Lo + Integer (Span * Long_Long_Integer (C)
                            / Long_Long_Integer (Clusters));
            Offs   : constant Integer :=
              Integer (Next_Mod (2 * Width + 1)) - Width;
            V      : Long_Long_Integer :=
              Long_Long_Integer (Center) + Long_Long_Integer (Offs);
         begin
            if V < Long_Long_Integer (Lo) then
               V := Long_Long_Integer (Lo);
            elsif V > Long_Long_Integer (Hi) then
               V := Long_Long_Integer (Hi);
            end if;
            A (I) := Integer (V);
         end;
      end loop;
      return A;
   end Clustered;

begin
   Put_Line ("Samplesort (SPARK) tests");
   Put_Line ("========================");

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
   Expect_Sorted ([0], "zero singleton via Expect");
   Expect_Sorted ([-7], "negative singleton via Expect");

   ---------------------------------------------------------------------
   Section ("2. Sorted, reverse, two-element");
   ---------------------------------------------------------------------
   Expect_Sorted ([1, 2], "two sorted");
   Expect_Sorted ([2, 1], "two reversed");
   Expect_Sorted ([5, 5], "two equal");
   Expect_Sorted ([1, 2, 3, 4, 5], "already sorted 5");
   Expect_Sorted ([5, 4, 3, 2, 1], "reverse 5");
   Expect_Sorted ([9, 8, 7, 6, 5, 4, 3, 2, 1, 0], "reverse 10");
   Expect_Sorted ([1, 2, 3, 5, 4], "almost sorted");
   Expect_Sorted ([3, 1, 2], "tiny 3");
   Expect_Sorted ([9, 0, 5, 1, 8, 3], "mixed small");
   Expect_Sorted ([1, 0], "two swapped with zero");
   Expect_Sorted ([100, 100], "two equal 100");

   ---------------------------------------------------------------------
   Section ("3. Duplicates and all-equal");
   ---------------------------------------------------------------------
   Expect_Sorted ([2, 2, 2, 2], "all equal 4");
   Expect_Sorted ([7, 7, 7], "all equal 3");
   Expect_Sorted ([0, 0, 0, 0, 0], "all zeros");
   Expect_Sorted ([5, 3, 5, 3, 5, 1, 1], "many dups");
   Expect_Sorted ([7, 7, 7, 1, 1, 9, 9, 9, 9], "runs of equals");
   Expect_Sorted ([0, 0, 0, 0, 0, 1, 0], "zeros with one");
   Expect_Sorted ([2, 1, 2, 1, 2, 1], "alternating");
   Expect_Sorted ([0, 1, 0, 1, 0, 1, 0], "binary keys");
   Expect_Sorted ([4, 4, 4, 2, 2, 2, 4, 2], "two-value multiset");

   ---------------------------------------------------------------------
   Section ("4. Negatives and Integer extremes");
   ---------------------------------------------------------------------
   Expect_Sorted ([-3, -1, -2], "all negative");
   Expect_Sorted ([-5, 0, 5, -2, 3], "neg+pos");
   Expect_Sorted ([-10, -10, 10, 0, -1], "neg+pos dups");
   Expect_Sorted ([-100, 50, -50, 0, 100, -1], "wider signed");
   Expect_Sorted ([-1, 1], "two signed");
   Expect_Sorted ([Integer'First + 10, Integer'First + 5,
                   Integer'First + 7], "near Integer'First");
   Expect_Sorted ([Integer'Last - 3, Integer'Last, Integer'Last - 1],
                  "near Integer'Last");
   Expect_Sorted ([Integer'First, 0, Integer'Last],
                  "full Integer span");
   Expect_Sorted ([Integer'Last, Integer'First], "two Integer extremes");
   Expect_Sorted ([Integer'First, Integer'First, Integer'Last],
                  "First dups plus Last");
   Expect_Sorted ([Integer'First / 4, 0, Integer'Last / 4, -1, 1],
                  "large magnitude ints");

   ---------------------------------------------------------------------
   Section ("5. In_Bounds / Max_N / Num_Buckets shape");
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
   Check (Nat (Num_Buckets) = 8, "Num_Buckets is 8");
   Check (Nat (Max_N) = 64, "Max_N is 64");

   ---------------------------------------------------------------------
   Section ("6. Uniform-ish / random vs reference");
   ---------------------------------------------------------------------
   Expect_Sorted (Random_Array (20, 0, 9), "random n=20 range 0..9");
   Expect_Sorted (Random_Array (50, -20, 20), "random n=50 range -20..20");
   Expect_Sorted (Random_Array (64, 1, 5), "random n=64 range 1..5");
   Expect_Sorted (Random_Array (64, -3, 3), "random n=64 range -3..3");
   Expect_Sorted (Random_Array (30, -100, -90), "random negative band");
   Expect_Sorted (Uniform_Ish (40), "uniform-ish n=40");
   Expect_Sorted (Uniform_Ish (64), "uniform-ish n=64");
   Expect_Sorted (Random_Array (48, 0, 10_000), "random wide uniform span");
   Expect_Sorted (Random_Array (25, -100, 100), "random wide signed");
   Expect_Sorted (Random_Array (32, -50, 50), "random n=32 signed");
   Expect_Sorted (Random_Array (16, 0, 0), "random all-zero span");
   Expect_Sorted (Random_Array (7, -5, 5), "random n=7 tiny");

   ---------------------------------------------------------------------
   Section ("7. Clustered / gapped keys / samplesort thresholds");
   ---------------------------------------------------------------------
   Expect_Sorted ([1, 1, 1, 1, 1, 100, 100, 100, 100, 100],
                  "two extreme clusters");
   Expect_Sorted ([0, 0, 0, 50, 50, 50, 100, 100, 100],
                  "three clusters");
   Expect_Sorted ([1, 1000, 2, 1000, 3, 1000], "gapped pairs");
   Expect_Sorted (Clustered (60, 3, 0, 1_000), "clustered n=60 C=3");
   Expect_Sorted (Clustered (64, 5, -500, 500), "clustered n=64 C=5 signed");
   Expect_Sorted ([10, 10, 10, 10, 10, 10, 10, 10, 10, 99],
                  "nine low plus one high");
   Expect_Sorted ([0, 1_000_000, 2, 3, 4, 5, 6, 7],
                  "one huge outlier");
   --  n around Num_Buckets: below → Bubble_Finish only; at/above → sample.
   Expect_Sorted (Uniform_Ish (7), "n=7 below Num_Buckets");
   Expect_Sorted (Uniform_Ish (8), "n=8 equals Num_Buckets");
   Expect_Sorted (Uniform_Ish (9), "n=9 just above Num_Buckets");
   Expect_Sorted (Uniform_Ish (16), "n=16 two strides");
   Expect_Sorted (Uniform_Ish (24), "n=24 three strides");

   ---------------------------------------------------------------------
   Section ("8. Is_Sorted predicate");
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
   Section ("9. Idempotence and edge patterns");
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
   Expect_Sorted ([2, 2, 1], "two+one");
   Expect_Sorted ([1, 3, 2, 4, 3, 5, 4], "saw-ish");
   Expect_Sorted ([1, 2, 3, 4, 5, 4, 3, 2, 1], "organ pipe");
   Expect_Sorted ([5, 1, 4, 2, 3, 3, 2, 4, 1, 5], "pyramid");
   Expect_Sorted ([-8, -3, -8, 0, 4, 4, -3], "signed dups mixed");
   Expect_Sorted ([1, 1, 2, 2, 3, 3, 4, 4, 5, 5], "paired ascending");
   Expect_Sorted ([5, 5, 4, 4, 3, 3, 2, 2, 1, 1], "paired descending");
   declare
      A : Element_Array (1 .. 63);
   begin
      for I in A'Range loop
         A (I) := (I * 17) rem 63;
      end loop;
      Expect_Sorted (A, "linear congruential n=63");
   end;
   declare
      A : Element_Array (1 .. 64);
   begin
      for I in A'Range loop
         A (I) := 65 - I;
      end loop;
      Expect_Sorted (A, "reverse n=64");
   end;

   New_Line;
   Put_Line
     ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image
      & " FAIL");

   if Fail_Count /= 0 then
      raise Program_Error with "Samplesort tests failed";
   end if;
end Tests;
