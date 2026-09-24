--  Standalone test suite for Pancake_Sorting (SPARK port).
--  Preconditions replace exceptions; only valid call paths are exercised.
--  A'First is always 1; Max_N = 64. Sortedness is proved by SPARK;
--  multiset / permutation equality is checked here.

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Pancake_Sorting; use Pancake_Sorting;

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

   procedure Expect_Bounded (Src : Element_Array; Label : String) is
      A      : Element_Array := Copy_Of (Src);
      Orig   : constant Element_Array := Copy_Of (Src);
      N      : constant Natural := Src'Length;
      Flips  : Flip_Sequence;
      Count  : Natural;
      Replay : Element_Array := Copy_Of (Src);
   begin
      Sort (A, Flips, Count);
      Check (Boo (Is_Sorted (A)), Label & " recorded Is_Sorted");
      Check (Count <= Classic_Flip_Bound (N), Label & " flip bound");
      Check (Is_Permutation (A, Orig), Label & " recorded permutation");
      Apply_Flips (Replay, Flips, Count);
      Check (Same (A, Replay), Label & " replay matches");
   end Expect_Bounded;

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

begin
   Put_Line ("Pancake_Sorting (SPARK) tests");
   Put_Line ("=============================");

   ---------------------------------------------------------------------
   Section ("1. Empty and singleton");
   ---------------------------------------------------------------------
   declare
      E : Element_Array (1 .. 0);
      S : Element_Array (1 .. 1) := [42];
      Z : Element_Array (1 .. 1) := [0];
      F : Flip_Sequence;
      C : Natural;
   begin
      Check (In_Bounds (E), "empty In_Bounds");
      Check (Boo (Is_Sorted (E)), "empty Is_Sorted");
      Sort (E);
      Check (Boo (Is_Sorted (E)), "empty Sort no-op");
      Check (In_Bounds (S), "singleton In_Bounds");
      Check (Boo (Is_Sorted (S)), "singleton Is_Sorted");
      Sort (S);
      Check (Int (S (1)) = 42, "singleton Sort preserves");
      Sort (Z, F, C);
      Check (Int (Z (1)) = 0 and then Nat (C) = 0,
             "singleton recorded 0 flips");
      Check (Nat (Classic_Flip_Bound (0)) = 0, "bound n=0");
      Check (Nat (Classic_Flip_Bound (1)) = 0, "bound n=1");
   end;

   ---------------------------------------------------------------------
   Section ("2. Flip primitive");
   ---------------------------------------------------------------------
   declare
      A : Element_Array := [1, 2, 3, 4, 5];
   begin
      Flip (A, 0);
      Check (Same (A, [1, 2, 3, 4, 5]), "Flip K=0 no-op");
      Flip (A, 1);
      Check (Same (A, [1, 2, 3, 4, 5]), "Flip K=1 no-op");
      Flip (A, 3);
      Check (Same (A, [3, 2, 1, 4, 5]), "Flip K=3 reverses prefix");
      Flip (A, 5);
      Check (Same (A, [5, 4, 1, 2, 3]), "Flip K=n reverses all");
      Flip (A, 2);
      Check (Same (A, [4, 5, 1, 2, 3]), "Flip K=2 swaps first pair");
   end;

   ---------------------------------------------------------------------
   Section ("3. Basic permutations");
   ---------------------------------------------------------------------
   Expect_Sorted ([1, 2, 3], "already sorted");
   Expect_Sorted ([3, 2, 1], "reversed");
   Expect_Sorted ([2, 1, 3], "rotated");
   Expect_Sorted ([5, 1, 4, 2, 3], "mixed 5");
   Expect_Sorted ([1, 3, 2], "n=3 hardest (1,3,2)");
   Expect_Sorted ([4, 3, 2, 1], "n=4 reversed");
   Expect_Sorted ([2, 3, 4, 1], "max at front");
   Expect_Sorted ([1, 4, 2, 3], "max in middle");

   ---------------------------------------------------------------------
   Section ("4. Duplicates and general Integers");
   ---------------------------------------------------------------------
   Expect_Sorted ([3, 1, 3, 2, 1, 3], "dups mixed");
   Expect_Sorted ([7, 7, 7, 7], "all equal");
   Expect_Sorted ([0, 0, 0], "all zeros");
   Expect_Sorted ([9, 0, 9, 0, 5], "zeros and nines");
   Expect_Sorted ([-3, -1, -2], "negatives");
   Expect_Sorted ([-5, 0, 5, -2, 3], "mixed signs");
   Expect_Sorted ([2, 2, -2, -2, 0], "signed dups");
   Expect_Sorted (
     [Integer'First + 10, -1, Integer'Last - 10], "near extremes");

   ---------------------------------------------------------------------
   Section ("5. Flip-count bound 2n-3 and replay");
   ---------------------------------------------------------------------
   Check (Nat (Classic_Flip_Bound (2)) = 1, "bound n=2");
   Check (Nat (Classic_Flip_Bound (3)) = 3, "bound n=3");
   Check (Nat (Classic_Flip_Bound (4)) = 5, "bound n=4");
   Check (Nat (Classic_Flip_Bound (10)) = 17, "bound n=10");
   Expect_Bounded ([1, 2, 3, 4], "sorted uses few flips");
   Expect_Bounded ([4, 3, 2, 1], "reversed bound");
   Expect_Bounded ([1, 3, 2], "n=3 (1,3,2) bound");
   Expect_Bounded ([3, 1, 4, 2, 5], "mixed bound");
   Expect_Bounded ([-2, 8, 8, -2, 0, 5], "dups bound");
   Expect_Bounded ([42], "singleton bound");

   ---------------------------------------------------------------------
   Section ("6. Already-sorted uses zero flips");
   ---------------------------------------------------------------------
   declare
      A     : Element_Array := [1, 2, 2, 3, 9];
      Flips : Flip_Sequence;
      Count : Natural;
   begin
      Sort (A, Flips, Count);
      Check (Nat (Count) = 0, "nondecreasing recorded 0 flips");
      Check (Boo (Is_Sorted (A)), "still sorted");
   end;

   ---------------------------------------------------------------------
   Section ("7. Pseudo-random sequences vs reference");
   ---------------------------------------------------------------------
   for Trial in 1 .. 8 loop
      declare
         N   : constant Positive := 3 + (Trial mod 12);
         Src : Element_Array (1 .. N);
      begin
         for I in Src'Range loop
            Src (I) := Integer (Next_Mod (80)) - 20;
         end loop;
         Expect_Sorted (Src, "rand #" & Trial'Image);
         Expect_Bounded (Src, "rand bound #" & Trial'Image);
      end;
   end loop;

   ---------------------------------------------------------------------
   Section ("8. In_Bounds at Max_N");
   ---------------------------------------------------------------------
   declare
      Full : Element_Array (1 .. Max_N);
   begin
      for I in Full'Range loop
         Full (I) := Integer (Max_N - I + 1);
      end loop;
      Check (In_Bounds (Full), "Max_N In_Bounds");
      Expect_Sorted (Full, "Max_N reversed");
   end;

   ---------------------------------------------------------------------
   Section ("9. Is_Sorted edge cases");
   ---------------------------------------------------------------------
   Check (Boo (Is_Sorted ([1, 2, 2, 3])), "nondecreasing with dups");
   Check (not Boo (Is_Sorted ([1, 3, 2])), "detects inversion");
   Check (not Boo (Is_Sorted ([2, 1])), "pair inversion");
   Check (Boo (Is_Sorted ([0])), "single zero");
   Check (Boo (Is_Sorted ([-5, -5, -1, 0, 10])), "signed ascending");
   Check (not Boo (Is_Sorted ([0, -1])), "signed inversion");

   ---------------------------------------------------------------------
   Section ("10. Idempotence and Apply_Flips");
   ---------------------------------------------------------------------
   declare
      A : Element_Array := [4, 1, 3, 2, 0, 5];
      F : Flip_Sequence;
      N : Natural;
   begin
      Sort (A, F, N);
      declare
         Once : constant Element_Array := A;
      begin
         Sort (A);
         Check (Same (A, Once), "Sort idempotent");
         Check (N <= Classic_Flip_Bound (6), "n=6 bound after record");
         Check (Is_Permutation (A, [4, 1, 3, 2, 0, 5]),
                "idempotent permutation vs original");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("11. Larger random run (within Max_N)");
   ---------------------------------------------------------------------
   declare
      N   : constant Positive := 32;
      Src : Element_Array (1 .. N);
   begin
      for I in Src'Range loop
         Src (I) := Integer (Next_Mod (500)) - 100;
      end loop;
      Expect_Sorted (Src, "n=32");
      Expect_Bounded (Src, "n=32 bound");
   end;

   ---------------------------------------------------------------------
   Section ("12. Prefix already at front / already in place");
   ---------------------------------------------------------------------
   Expect_Sorted ([1, 2, 4, 3], "almost sorted");
   Expect_Bounded ([5, 1, 2, 3, 4], "max at front");
   Expect_Bounded ([1, 5, 2, 3, 4], "max second");

   ---------------------------------------------------------------------
   Section ("13. Worked OEIS n=3 example (1,3,2)");
   ---------------------------------------------------------------------
   declare
      A     : Element_Array := [1, 3, 2];
      Flips : Flip_Sequence;
      Count : Natural;
   begin
      Sort (A, Flips, Count);
      Check (Same (A, [1, 2, 3]), "OEIS (1,3,2) sorts to (1,2,3)");
      Check (Count <= 3, "OEIS (1,3,2) within P(3)=3 classic bound");
      Check (Count >= 1, "OEIS (1,3,2) needs at least one flip");
      Check (Is_Permutation (A, [1, 3, 2]), "OEIS permutation");
   end;

   New_Line;
   Put_Line
     ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image
      & " FAIL");

   if Fail_Count /= 0 then
      raise Program_Error with "Pancake_Sorting tests failed";
   end if;
end Tests;
