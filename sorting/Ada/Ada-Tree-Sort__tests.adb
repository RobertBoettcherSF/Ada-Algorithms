--  Standalone test suite for Tree_Sort (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Tree_Sort; use Tree_Sort;

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

   --  Insertion-sort reference (ascending, stable).
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
   ---------------------------------------------------------------------
   Section ("1. Empty and singleton");
   ---------------------------------------------------------------------
   declare
      Empty : Element_Array (1 .. 0);
      One   : Element_Array := [42];
      Neg   : Element_Array := [-7];
   begin
      Check (Is_Sorted (Empty), "empty Is_Sorted");
      Sort (Empty);
      Check (Is_Sorted (Empty), "empty after Sort");
      Check (Is_Sorted (One), "singleton Is_Sorted");
      Sort (One);
      Check (One (One'First) = 42, "singleton value preserved");
      Check (Is_Sorted (One), "singleton after Sort");
      Sort (Neg);
      Check (Neg (Neg'First) = -7, "negative singleton preserved");
      Check (Is_Sorted (Neg), "negative singleton Is_Sorted");
   end;

   ---------------------------------------------------------------------
   Section ("2. Small patterns");
   ---------------------------------------------------------------------
   Expect_Sorted ([3, 1, 2], "tiny 3");
   Expect_Sorted ([5, 4, 3, 2, 1], "reverse 5");
   Expect_Sorted ([1, 2, 3, 4, 5], "already sorted");
   Expect_Sorted ([2, 2, 2, 2], "all equal");
   Expect_Sorted ([9, 0, 5, 1, 8, 3], "mixed with zero");
   Expect_Sorted ([5, 3, 7, 4, 6, 3], "worked BST example");
   Expect_Sorted ([1, 0], "two swapped with zero");
   Expect_Sorted ([100, 100], "two equal");
   Expect_Sorted ([2, 1, 2, 1, 2, 1], "alternating");
   Expect_Sorted ([1, 2, 3, 5, 4], "almost sorted");
   Expect_Sorted ([9, 8, 7, 6, 5, 4, 3, 2, 1, 0], "reverse 10 with zero");
   Expect_Sorted ([0, 1, 0, 1, 0, 1, 0], "binary keys");
   Expect_Sorted ([0, 0, 0, 0], "all zeros");
   Expect_Sorted ([7], "singleton via Expect");

   ---------------------------------------------------------------------
   Section ("3. Negatives and duplicates");
   ---------------------------------------------------------------------
   Expect_Sorted ([-3, -1, -2], "three negatives");
   Expect_Sorted ([-5, 0, 5, -2, 2], "negatives mixed");
   Expect_Sorted ([-1, -1, -1], "all equal negatives");
   Expect_Sorted ([5, 3, 5, 3, 5, 1, 1], "many dups");
   Expect_Sorted ([7, 7, 7, 1, 1, 9, 9, 9, 9], "runs of equals");
   Expect_Sorted ([-10, 10, -5, 5, 0], "symmetric around zero");
   Expect_Sorted ([4, 4, 4, 2, 2, 2, 4, 2], "two-value multiset");
   Expect_Sorted ([10, 1, 10, 1, 10, 1, 10], "high-low alternating");

   ---------------------------------------------------------------------
   Section ("4. Equals-right stability (tagged keys)");
   ---------------------------------------------------------------------
   declare
      --  Encode (key, arrival_tag) as key*1000 + tag so equal keys keep
      --  tags in increasing order after a stable sort.
      --  Keys 2,1,2,1,2 with tags 1..5 → values 2001,1002,2003,1004,2005.
      A : Element_Array := [2001, 1002, 2003, 1004, 2005];
      R : Element_Array := Copy_Of (A);
   begin
      Sort (A);
      Reference_Sort (R);
      Check (Same (A, R), "tagged multiset matches reference");
      Check (Is_Sorted (A), "tagged array Is_Sorted");
      Check (A (A'First) = 1002 and then A (A'First + 1) = 1004,
             "key-1 tags stable order");
      Check (A (A'First + 2) = 2001
             and then A (A'First + 3) = 2003
             and then A (A'First + 4) = 2005,
             "key-2 tags stable order");
   end;
   declare
      A : Element_Array := [5001, 5002, 5003, 1004, 1005];
   begin
      Sort (A);
      Check (A (A'First) = 1004 and then A (A'First + 1) = 1005,
             "key-1 pair stable");
      Check (A (A'First + 2) = 5001
             and then A (A'First + 3) = 5002
             and then A (A'First + 4) = 5003,
             "key-5 triple stable");
   end;
   Expect_Sorted ([3, 3, 3, 1, 2, 3], "leading equals then rest");
   Expect_Sorted ([1, 2, 3, 3, 3], "trailing equals");

   ---------------------------------------------------------------------
   Section ("5. Arbitrary bounds (non-1 First)");
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
   Section ("6. Random arrays vs reference");
   ---------------------------------------------------------------------
   Expect_Sorted (Random_Array (20, 0, 9), "random n=20 range 0..9");
   Expect_Sorted (Random_Array (50, -10, 20), "random n=50 range -10..20");
   Expect_Sorted (Random_Array (100, 1, 5), "random n=100 range 1..5");
   Expect_Sorted (Random_Array (64, -3, 3), "random n=64 range -3..3");
   Expect_Sorted (Random_Array (30, 90, 100), "random high band");
   Expect_Sorted (Random_Array (16, 0, 0), "random all-zero span");
   Expect_Sorted (Random_Array (40, 1, 1), "random all-ones");
   Expect_Sorted (Random_Array (25, -100, 100), "random wide signed");
   Expect_Sorted (Random_Array (80, -50, 50), "random n=80 signed");
   Expect_Sorted (Random_Array (128, -20, 20), "random n=128 signed");
   Expect_Sorted (Random_Array (200, 0, 15), "random n=200 small range");
   Expect_Sorted (Random_Array (12, -1000, 1000), "random n=12 wide");
   Expect_Sorted (Random_Array (7, -5, 5), "random n=7 tiny");

   ---------------------------------------------------------------------
   Section ("7. Is_Sorted predicate");
   ---------------------------------------------------------------------
   Check (Is_Sorted ([1, 2, 3, 4]), "ascending true");
   Check (Is_Sorted ([1, 1, 2, 2]), "nondecreasing true");
   Check (not Is_Sorted ([1, 3, 2]), "inversion false");
   Check (not Is_Sorted ([5, 4, 3]), "reverse false");
   Check (Is_Sorted ([7]), "singleton true");
   Check (Is_Sorted ([0, 0, 0]), "zeros nondecreasing");
   Check (not Is_Sorted ([0, 2, 1]), "zero then inversion false");
   Check (Is_Sorted ([-3, -2, -1, 0]), "negatives ascending");
   Check (not Is_Sorted ([-1, -3]), "negatives inversion false");
   declare
      E : Element_Array (1 .. 0);
   begin
      Check (Is_Sorted (E), "empty true");
   end;
   Check (Is_Sorted ([1, 2]), "two ascending true");
   Check (not Is_Sorted ([2, 1]), "two descending false");

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
      Mid : Element_Array := Random_Array (128, -20, 50);
      R   : Element_Array := Copy_Of (Mid);
   begin
      Sort (Mid);
      Reference_Sort (R);
      Check (Same (Mid, R), "n=128 random matches reference");
      Check (Is_Sorted (Mid), "n=128 Is_Sorted");
   end;
   declare
      Edge : Element_Array (1 .. Max_N) := [others => 1];
   begin
      --  All-equal is a right spine (equals go right); O(n²) but n=4096
      --  is still a short demo.
      Sort (Edge);
      Check (Is_Sorted (Edge), "n = Max_N all equal sorts");
   end;

   ---------------------------------------------------------------------
   Section ("9. Degenerate BST spines");
   ---------------------------------------------------------------------
   Expect_Sorted ([1, 2], "two ascending");
   Expect_Sorted ([2, 1], "two descending");
   Expect_Sorted ([0, 0], "two zeros");
   Expect_Sorted ([-100, 100, -50], "sparse signed");
   Expect_Sorted ([15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1],
                  "reverse 15 (left spine)");
   Expect_Sorted ([1, 3, 5, 7, 9, 2, 4, 6, 8, 10], "odds then evens");
   Expect_Sorted ([8, 0, 8, 0, 8, 0, 8, 0], "sparse high/zero");
   declare
      A : Element_Array (1 .. 10);
   begin
      for I in A'Range loop
         A (I) := I;
      end loop;
      Expect_Sorted (A, "identity 1..10 (right spine)");
   end;
   declare
      A : Element_Array (1 .. 10);
   begin
      for I in A'Range loop
         A (I) := 11 - I;
      end loop;
      Expect_Sorted (A, "countdown 10..1 (left spine)");
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

   ---------------------------------------------------------------------
   Section ("10. Idempotence");
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
         Check (Is_Sorted (A), "idempotent still sorted");
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
      A : Element_Array := [5, 5, 5, 5];
   begin
      Sort (A);
      declare
         B : constant Element_Array := Copy_Of (A);
      begin
         Sort (A);
         Check (Same (A, B), "idempotent on all-equal");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("11. More lengths, magnitudes, shapes");
   ---------------------------------------------------------------------
   Expect_Sorted ([3, 3, 2, 2, 1, 1], "dup reverse pairs");
   Expect_Sorted ([Integer'First / 4, 0, Integer'Last / 4, -1, 1],
                  "large magnitude ints");
   Expect_Sorted ([4, 2, 6, 1, 3, 5, 7], "heap-like level order");
   Expect_Sorted ([1, 8, 2, 7, 3, 6, 4, 5], "interleaved");
   Expect_Sorted ([-7, -7, 0, 0, 7, 7], "paired signed");
   Expect_Sorted ([9, 1, 8, 2, 7, 3, 6, 4, 5], "unbalanced mix");
   declare
      A : Element_Array (1 .. 16);
   begin
      for I in A'Range loop
         A (I) := (I rem 4);
      end loop;
      Expect_Sorted (A, "mod-4 repeating n=16");
   end;
   declare
      A : Element_Array (1 .. 31);
   begin
      for I in A'Range loop
         A (I) := (if I rem 2 = 0 then I else -I);
      end loop;
      Expect_Sorted (A, "signed zigzag n=31");
   end;
   declare
      A : Element_Array (1 .. 48);
   begin
      for I in A'Range loop
         A (I) := 24 - I;
      end loop;
      Expect_Sorted (A, "descending through zero n=48");
   end;
   Expect_Sorted ([42, -42], "two opposites");
   Expect_Sorted ([0, -1, 1], "zero and neighbors");
   Expect_Sorted ([6, 5, 4, 3, 2, 1, 0, -1], "strict reverse signed");

   New_Line;
   Put_Line
     ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image
      & " FAIL");

   if Fail_Count /= 0 then
      raise Program_Error with "Tree_Sort tests failed";
   end if;
end Tests;
