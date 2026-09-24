--  Standalone test suite for Bead_Sort (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Bead_Sort; use Bead_Sort;

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

   --  Insertion-sort reference (ascending).
   procedure Reference_Sort (A : in out Element_Array) is
   begin
      if A'Length <= 1 then
         return;
      end if;
      for I in A'First + 1 .. A'Last loop
         declare
            Key : constant Natural := A (I);
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
     (Len : Natural; Lo, Hi : Natural) return Element_Array
   is
      Span : constant Positive := Hi - Lo + 1;
      A    : Element_Array (1 .. Len);
   begin
      for I in A'Range loop
         A (I) := Lo + Next_Mod (Span);
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
      Zero  : Element_Array := [0];
   begin
      Check (Is_Sorted (Empty), "empty Is_Sorted");
      Sort (Empty);
      Check (Is_Sorted (Empty), "empty after Sort");
      Check (Is_Sorted (One), "singleton Is_Sorted");
      Sort (One);
      Check (One (One'First) = 42, "singleton value preserved");
      Check (Is_Sorted (One), "singleton after Sort");
      Sort (Zero);
      Check (Zero (Zero'First) = 0, "zero singleton preserved");
      Check (Is_Sorted (Zero), "zero singleton Is_Sorted");
   end;

   ---------------------------------------------------------------------
   Section ("2. Small patterns");
   ---------------------------------------------------------------------
   Expect_Sorted ([3, 1, 2], "tiny 3");
   Expect_Sorted ([5, 4, 3, 2, 1], "reverse 5");
   Expect_Sorted ([1, 2, 3, 4, 5], "already sorted");
   Expect_Sorted ([2, 2, 2, 2], "all equal");
   Expect_Sorted ([9, 0, 5, 1, 8, 3], "mixed with zero");
   Expect_Sorted ([3, 2, 4, 2], "wiki-style example");
   Expect_Sorted ([1, 0], "two swapped with zero");
   Expect_Sorted ([100, 100], "two equal");
   Expect_Sorted ([2, 1, 2, 1, 2, 1], "alternating");
   Expect_Sorted ([1, 2, 3, 5, 4], "almost sorted");
   Expect_Sorted ([9, 8, 7, 6, 5, 4, 3, 2, 1, 0], "reverse 10 with zero");
   Expect_Sorted ([0, 1, 0, 1, 0, 1, 0], "binary keys");
   Expect_Sorted ([0, 0, 0, 0], "all zeros");
   Expect_Sorted ([7], "singleton via Expect");

   ---------------------------------------------------------------------
   Section ("3. Duplicates and runs");
   ---------------------------------------------------------------------
   Expect_Sorted ([5, 3, 5, 3, 5, 1, 1], "many dups");
   Expect_Sorted ([7, 7, 7, 1, 1, 9, 9, 9, 9], "runs of equals");
   Expect_Sorted ([0, 0, 0, 0, 0, 1, 0], "zeros with one");
   Expect_Sorted ([4, 4, 4, 2, 2, 2, 4, 2], "two-value multiset");
   Expect_Sorted ([10, 1, 10, 1, 10, 1, 10], "high-low alternating");

   ---------------------------------------------------------------------
   Section ("4. Arbitrary bounds (non-1 First)");
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

   ---------------------------------------------------------------------
   Section ("5. Random arrays vs reference");
   ---------------------------------------------------------------------
   Expect_Sorted (Random_Array (20, 0, 9), "random n=20 range 0..9");
   Expect_Sorted (Random_Array (50, 0, 20), "random n=50 range 0..20");
   Expect_Sorted (Random_Array (100, 1, 5), "random n=100 range 1..5");
   Expect_Sorted (Random_Array (64, 0, 3), "random n=64 range 0..3");
   Expect_Sorted (Random_Array (30, 90, 100), "random high band");
   Expect_Sorted (Random_Array (16, 0, 0), "random all-zero span");
   Expect_Sorted (Random_Array (40, 1, 1), "random all-ones");
   Expect_Sorted (Random_Array (25, 0, Max_Value / 4),
                  "random modest Max_Value/4");

   ---------------------------------------------------------------------
   Section ("6. Is_Sorted predicate");
   ---------------------------------------------------------------------
   Check (Is_Sorted ([1, 2, 3, 4]), "ascending true");
   Check (Is_Sorted ([1, 1, 2, 2]), "nondecreasing true");
   Check (not Is_Sorted ([1, 3, 2]), "inversion false");
   Check (not Is_Sorted ([5, 4, 3]), "reverse false");
   Check (Is_Sorted ([7]), "singleton true");
   Check (Is_Sorted ([0, 0, 0]), "zeros nondecreasing");
   Check (not Is_Sorted ([0, 2, 1]), "zero then inversion false");
   declare
      E : Element_Array (1 .. 0);
   begin
      Check (Is_Sorted (E), "empty true");
   end;

   ---------------------------------------------------------------------
   Section ("7. Invalid_Argument — value too large");
   ---------------------------------------------------------------------
   declare
      Big : constant Element_Array := [1, Max_Value + 1];
   begin
      Check (Sort_Raises (Big), "value Max_Value+1 raises");
   end;
   declare
      Big2 : constant Element_Array := [Max_Value + 50];
   begin
      Check (Sort_Raises (Big2), "singleton oversize value raises");
   end;
   declare
      Ok : Element_Array := [0, Max_Value];
   begin
      Sort (Ok);
      Check (Is_Sorted (Ok), "exact Max_Value sorts");
      Check (Ok (Ok'First) = 0 and then Ok (Ok'Last) = Max_Value,
             "exact Max_Value placement");
   end;
   declare
      Ok2 : Element_Array := [Max_Value, Max_Value, 1];
   begin
      Sort (Ok2);
      Check (Is_Sorted (Ok2), "Max_Value duplicates sort");
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
   end;
   declare
      Mid : Element_Array := Random_Array (128, 0, 50);
      R   : Element_Array := Copy_Of (Mid);
   begin
      Sort (Mid);
      Reference_Sort (R);
      Check (Same (Mid, R), "n=128 random matches reference");
      Check (Is_Sorted (Mid), "n=128 Is_Sorted");
   end;

   ---------------------------------------------------------------------
   Section ("9. Edge patterns and larger M");
   ---------------------------------------------------------------------
   Expect_Sorted ([1, 2], "two ascending");
   Expect_Sorted ([2, 1], "two descending");
   Expect_Sorted ([0, 0], "two zeros");
   Expect_Sorted ([Max_Value / 2, 1, Max_Value / 2], "half-max dups");
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

   ---------------------------------------------------------------------
   Section ("10. Idempotence");
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
         Check (Is_Sorted (A), "idempotent still sorted");
      end;
   end;

   New_Line;
   Put_Line
     ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image
      & " FAIL");

   if Fail_Count /= 0 then
      raise Program_Error with "Bead_Sort tests failed";
   end if;
end Tests;
