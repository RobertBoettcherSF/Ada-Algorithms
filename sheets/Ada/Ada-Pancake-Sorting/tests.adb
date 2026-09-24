--  Standalone test suite for Pancake_Sorting (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Pancake_Sorting; use Pancake_Sorting;

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

   function Flip_Raises (A : Element_Array; K : Natural) return Boolean is
      T : Element_Array := A;
   begin
      Flip (T, K);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Flip_Raises;

   procedure Expect_Sorted (Src : Element_Array; Label : String) is
      A : Element_Array := Copy_Of (Src);
      R : Element_Array := Copy_Of (Src);
   begin
      Sort (A);
      Reference_Sort (R);
      Check (Is_Sorted (A), Label & " Is_Sorted");
      Check (Same (A, R), Label & " matches reference");
   end Expect_Sorted;

   procedure Expect_Bounded (Src : Element_Array; Label : String) is
      A     : Element_Array := Copy_Of (Src);
      Orig  : constant Element_Array := Copy_Of (Src);
      N     : constant Natural := Src'Length;
      Cap   : constant Natural :=
        (if N <= 1 then 1 else Classic_Flip_Bound (N));
      Flips : Flip_Sequence (1 .. Cap);
      Count : Natural;
      Replay : Element_Array := Copy_Of (Src);
   begin
      Sort (A, Flips, Count);
      Check (Is_Sorted (A), Label & " recorded Is_Sorted");
      Check (Count <= Classic_Flip_Bound (N), Label & " flip bound");
      Apply_Flips (Replay, Flips (1 .. Count));
      Check (Same (A, Replay), Label & " replay matches");
      Check (Same (Orig, Src), Label & " source unchanged");
   end Expect_Bounded;

   --  Deterministic LCG.
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
   ---------------------------------------------------------------------
   Section ("1. Empty and singleton");
   ---------------------------------------------------------------------
   declare
      E : Element_Array (1 .. 0);
      S : Element_Array (1 .. 1) := [42];
      Z : Element_Array (1 .. 1) := [0];
      F : Flip_Sequence (1 .. 1);
      C : Natural;
   begin
      Check (Is_Sorted (E), "empty Is_Sorted");
      Sort (E);
      Check (Is_Sorted (E), "empty Sort no-op");
      Check (Is_Sorted (S), "singleton Is_Sorted");
      Sort (S);
      Check (S (1) = 42, "singleton Sort preserves");
      Sort (Z, F, C);
      Check (Z (1) = 0 and then C = 0, "singleton recorded 0 flips");
      Check (Classic_Flip_Bound (0) = 0, "bound n=0");
      Check (Classic_Flip_Bound (1) = 0, "bound n=1");
   end;

   ---------------------------------------------------------------------
   Section ("2. Flip primitive (1-based logical bounds)");
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
      Check (Flip_Raises (A, 6), "Flip K > n raises");
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
   Check (Classic_Flip_Bound (2) = 1, "bound n=2");
   Check (Classic_Flip_Bound (3) = 3, "bound n=3");
   Check (Classic_Flip_Bound (4) = 5, "bound n=4");
   Check (Classic_Flip_Bound (10) = 17, "bound n=10");
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
      Flips : Flip_Sequence (1 .. Classic_Flip_Bound (5));
      Count : Natural;
   begin
      Sort (A, Flips, Count);
      Check (Count = 0, "nondecreasing recorded 0 flips");
      Check (Is_Sorted (A), "still sorted");
   end;

   ---------------------------------------------------------------------
   Section ("7. Pseudo-random sequences vs reference");
   ---------------------------------------------------------------------
   for Trial in 1 .. 10 loop
      declare
         N   : constant Positive := 3 + (Trial mod 14);
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
   Section ("8. Invalid_Argument — oversize");
   ---------------------------------------------------------------------
   declare
      Big : constant Element_Array (1 .. Max_Length + 1) := [others => 0];
      Ok  : constant Element_Array := [1, 2, 3];
      Tiny : Flip_Sequence (1 .. 0);
      C    : Natural;
      T    : Element_Array := [3, 2, 1];
   begin
      Check (Sort_Raises (Big), "Sort raises on oversize");
      Check (Flip_Raises (Big, 1), "Flip raises on oversize");
      Check (Flip_Raises (Ok, 4), "Flip raises on K > n");
      begin
         Sort (T, Tiny, C);
         Check (False, "tiny flip buffer should raise");
      exception
         when Invalid_Argument =>
            Check (True, "tiny flip buffer raises");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("9. Is_Sorted edge cases");
   ---------------------------------------------------------------------
   Check (Is_Sorted ([1, 2, 2, 3]), "nondecreasing with dups");
   Check (not Is_Sorted ([1, 3, 2]), "detects inversion");
   Check (not Is_Sorted ([2, 1]), "pair inversion");
   Check (Is_Sorted ([0]), "single zero");
   Check (Is_Sorted ([-5, -5, -1, 0, 10]), "signed ascending");
   Check (not Is_Sorted ([0, -1]), "signed inversion");

   ---------------------------------------------------------------------
   Section ("10. Non-1-based index bounds");
   ---------------------------------------------------------------------
   declare
      A : Element_Array (0 .. 4) := [4, 3, 2, 1, 0];
      B : Element_Array (10 .. 14) := [5, 4, 3, 2, 1];
      C : Element_Array (0 .. 3) := [1, 2, 3, 4];
   begin
      Sort (A);
      Check (Is_Sorted (A) and then A (0) = 0 and then A (4) = 4,
             "0-based pancake sort");
      Sort (B);
      Check (Is_Sorted (B) and then B (10) = 1 and then B (14) = 5,
             "10-based pancake sort");
      Flip (C, 3);
      Check (C (0) = 3 and then C (1) = 2 and then C (2) = 1
             and then C (3) = 4,
             "Flip K=3 on 0-based is logical prefix");
   end;

   ---------------------------------------------------------------------
   Section ("11. Idempotence and Apply_Flips");
   ---------------------------------------------------------------------
   declare
      A : Element_Array := [4, 1, 3, 2, 0, 5];
      F : Flip_Sequence (1 .. Classic_Flip_Bound (6));
      N : Natural;
   begin
      Sort (A, F, N);
      declare
         Once : constant Element_Array := A;
      begin
         Sort (A);
         Check (Same (A, Once), "Sort idempotent");
         Check (N <= Classic_Flip_Bound (6), "n=6 bound after record");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("12. Larger random run");
   ---------------------------------------------------------------------
   declare
      N   : constant Positive := 80;
      Src : Element_Array (1 .. N);
   begin
      for I in Src'Range loop
         Src (I) := Integer (Next_Mod (500)) - 100;
      end loop;
      Expect_Sorted (Src, "n=80");
      Expect_Bounded (Src, "n=80 bound");
   end;

   ---------------------------------------------------------------------
   Section ("13. Prefix already at front / already in place");
   ---------------------------------------------------------------------
   --  Max already at bottom of prefix → no flip for that Size.
   Expect_Sorted ([1, 2, 4, 3], "almost sorted");
   --  Max already at front → single flip of the whole prefix.
   Expect_Bounded ([5, 1, 2, 3, 4], "max at front");
   Expect_Bounded ([1, 5, 2, 3, 4], "max second");

   ---------------------------------------------------------------------
   Section ("14. Worked OEIS n=3 example (1,3,2)");
   ---------------------------------------------------------------------
   declare
      A     : Element_Array := [1, 3, 2];
      Flips : Flip_Sequence (1 .. 3);
      Count : Natural;
   begin
      Sort (A, Flips, Count);
      Check (Same (A, [1, 2, 3]), "OEIS (1,3,2) sorts to (1,2,3)");
      Check (Count <= 3, "OEIS (1,3,2) within P(3)=3 classic bound");
      Check (Count >= 1, "OEIS (1,3,2) needs at least one flip");
   end;

   New_Line;
   Put_Line
     ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image
      & " FAIL");

   if Fail_Count /= 0 then
      raise Program_Error with "Pancake_Sorting tests failed";
   end if;
end Tests;
