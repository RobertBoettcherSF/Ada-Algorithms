--  Standalone test suite for Selection_Sort (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Selection_Sort; use Selection_Sort;

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

   --  Descending reference via reverse of ascending sort.
   procedure Reference_Sort_Descending (A : in out Element_Array) is
   begin
      Reference_Sort (A);
      if A'Length <= 1 then
         return;
      end if;
      declare
         Lo : Natural := A'First;
         Hi : Natural := A'Last;
         T  : Integer;
      begin
         while Lo < Hi loop
            T := A (Lo);
            A (Lo) := A (Hi);
            A (Hi) := T;
            Lo := Lo + 1;
            Hi := Hi - 1;
         end loop;
      end;
   end Reference_Sort_Descending;

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

   function Sort_Desc_Raises (A : Element_Array) return Boolean is
      T : Element_Array := A;
   begin
      Sort_Descending (T);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Sort_Desc_Raises;

   procedure Expect_Sorted (Src : Element_Array; Label : String) is
      A : Element_Array := Copy_Of (Src);
      R : Element_Array := Copy_Of (Src);
   begin
      Sort (A);
      Reference_Sort (R);
      Check (Is_Sorted (A), Label & " Is_Sorted");
      Check (Same (A, R), Label & " matches reference");
   end Expect_Sorted;

   procedure Expect_Desc_Sorted (Src : Element_Array; Label : String) is
      A : Element_Array := Copy_Of (Src);
      R : Element_Array := Copy_Of (Src);
   begin
      Sort_Descending (A);
      Reference_Sort_Descending (R);
      Check (Is_Sorted_Descending (A), Label & " Is_Sorted_Descending");
      Check (Same (A, R), Label & " desc matches reference");
   end Expect_Desc_Sorted;

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

   function Random_Array (Len : Natural; Lo, Hi : Integer) return Element_Array
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
   ---------------------------------------------------------------------
   Section ("1. Empty and singleton");
   ---------------------------------------------------------------------
   declare
      E : Element_Array (1 .. 0);
      S : Element_Array (1 .. 1) := [42];
      Z : Element_Array (0 .. 0) := [0 => -7];
   begin
      Check (Is_Sorted (E), "empty Is_Sorted");
      Check (Is_Sorted_Descending (E), "empty Is_Sorted_Descending");
      Sort (E);
      Check (Is_Sorted (E), "empty Sort no-op");
      Sort_Descending (E);
      Check (Is_Sorted_Descending (E), "empty Sort_Descending no-op");
      Check (Is_Sorted (S), "singleton Is_Sorted");
      Sort (S);
      Check (S (1) = 42, "singleton Sort preserves");
      Sort_Descending (Z);
      Check (Z (0) = -7, "0-based singleton Sort_Descending preserves");
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

   ---------------------------------------------------------------------
   Section ("3. Wikipedia worked example");
   ---------------------------------------------------------------------
   --  Wikipedia: 64 25 12 22 11 → 11 12 22 25 64
   declare
      A : Element_Array := [64, 25, 12, 22, 11];
   begin
      Sort (A);
      Check (Same (A, [11, 12, 22, 25, 64]), "wiki example sorts to known");
      Check (Is_Sorted (A), "wiki example Is_Sorted");
   end;

   ---------------------------------------------------------------------
   Section ("4. Two-element and small permutations");
   ---------------------------------------------------------------------
   Expect_Sorted ([1, 2], "two ascending");
   Expect_Sorted ([2, 1], "two descending");
   Expect_Sorted ([1, 1], "two equal");
   Expect_Sorted ([3, 1, 2], "perm 3,1,2");
   Expect_Sorted ([2, 3, 1], "perm 2,3,1");
   Expect_Sorted ([1, 3, 2], "perm 1,3,2");

   ---------------------------------------------------------------------
   Section ("5. Negatives and extreme Integers");
   ---------------------------------------------------------------------
   Expect_Sorted ([-5, -1, -3, -2, -4], "all negatives");
   Expect_Sorted ([Integer'First, 0, Integer'Last], "extremes trio");
   Expect_Sorted
     ([Integer'Last, Integer'First, Integer'First + 1, -1],
      "extremes quartet");

   ---------------------------------------------------------------------
   Section ("6. Non-1-based bounds");
   ---------------------------------------------------------------------
   declare
      A : Element_Array (0 .. 4) := [0 => 9, 1 => 3, 2 => 7, 3 => 1, 4 => 5];
      R : Element_Array (0 .. 4);
   begin
      R := A;
      Sort (A);
      Reference_Sort (R);
      Check (Is_Sorted (A), "0-based Is_Sorted");
      Check (Same (A, R), "0-based matches reference");
   end;
   declare
      A : Element_Array (10 .. 14) :=
        [10 => 4, 11 => 2, 12 => 8, 13 => 6, 14 => 0];
      R : Element_Array (10 .. 14);
   begin
      R := A;
      Sort (A);
      Reference_Sort (R);
      Check (A (10) = 0 and then A (14) = 8, "10-based first/last");
      Check (Same (A, R), "10-based matches reference");
   end;

   ---------------------------------------------------------------------
   Section ("7. Sort_Descending");
   ---------------------------------------------------------------------
   Expect_Desc_Sorted ([1, 2, 3, 4, 5], "asc input desc");
   Expect_Desc_Sorted ([5, 4, 3, 2, 1], "already desc");
   Expect_Desc_Sorted ([3, 1, 4, 1, 5], "mixed desc");
   Expect_Desc_Sorted ([-1, 0, 1], "signed desc");
   declare
      A : Element_Array := [64, 25, 12, 22, 11];
   begin
      Sort_Descending (A);
      Check (Same (A, [64, 25, 22, 12, 11]), "wiki example descending");
      Check (Is_Sorted_Descending (A), "wiki desc Is_Sorted_Descending");
   end;

   ---------------------------------------------------------------------
   Section ("8. Is_Sorted predicates");
   ---------------------------------------------------------------------
   Check (Is_Sorted ([1, 2, 2, 3]), "nondecreasing true");
   Check (not Is_Sorted ([1, 3, 2]), "unsorted ascending false");
   Check (Is_Sorted_Descending ([9, 5, 5, 1]), "nonincreasing true");
   Check (not Is_Sorted_Descending ([9, 1, 5]), "unsorted descending false");

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
   Expect_Sorted (Random_Array (100, 0, 10), "random n=100 many dups");
   Expect_Desc_Sorted (Random_Array (20, -200, 200), "random desc n=20");
   Expect_Desc_Sorted (Random_Array (40, -10, 10), "random desc n=40");

   ---------------------------------------------------------------------
   Section ("10. Capacity / Invalid_Argument");
   ---------------------------------------------------------------------
   declare
      Big : constant Element_Array (1 .. Max_Length + 1) := [others => 0];
   begin
      Check (Sort_Raises (Big), "oversize Sort raises");
      Check (Sort_Desc_Raises (Big), "oversize Sort_Descending raises");
   end;
   declare
      Ok : Element_Array (1 .. 3) := [3, 1, 2];
   begin
      Sort (Ok);
      Check (Same (Ok, [1, 2, 3]), "under Max_Length still sorts");
   end;

   ---------------------------------------------------------------------
   Section ("11. Idempotence");
   ---------------------------------------------------------------------
   declare
      A : Element_Array := [9, 4, 1, 8, 2, 7, 3];
      B : Element_Array (A'Range);
   begin
      Sort (A);
      B := A;
      Sort (A);
      Check (Same (A, B), "Sort twice is idempotent");
      Check (Is_Sorted (A), "idempotent result still sorted");
   end;

   ---------------------------------------------------------------------
   Section ("12. Nearly sorted / single inversion");
   ---------------------------------------------------------------------
   Expect_Sorted ([1, 2, 3, 5, 4], "single swap near end");
   Expect_Sorted ([2, 1, 3, 4, 5], "single swap near start");
   Expect_Sorted ([1, 2, 2, 2, 1], "dups with inversion");

   New_Line;
   Put_Line
     ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image
      & " FAIL");

   if Fail_Count /= 0 then
      raise Program_Error with "Selection_Sort tests failed";
   end if;
end Tests;
