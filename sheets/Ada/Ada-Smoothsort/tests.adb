--  Standalone test suite for Smoothsort (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Smoothsort; use Smoothsort;

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

   function Leonardo_Raises (K : Natural) return Boolean is
      Unused : Natural;
   begin
      Unused := Leonardo (K);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Leonardo_Raises;

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

   function Sorted_Array (Len : Natural; Start : Integer := 1)
     return Element_Array
   is
      A : Element_Array (1 .. Len);
   begin
      for I in A'Range loop
         A (I) := Start + Integer (I - A'First);
      end loop;
      return A;
   end Sorted_Array;

   function Reverse_Array (Len : Natural) return Element_Array is
      A : Element_Array (1 .. Len);
   begin
      for I in A'Range loop
         A (I) := Integer (Len) - Integer (I - A'First);
      end loop;
      return A;
   end Reverse_Array;

begin
   Put_Line ("Smoothsort test suite (Ada 2023)");

   ---------------------------------------------------------------------
   Section ("1. Leonardo numbers");
   ---------------------------------------------------------------------
   Check (Leonardo (0) = 1, "L(0) = 1");
   Check (Leonardo (1) = 1, "L(1) = 1");
   Check (Leonardo (2) = 3, "L(2) = 3");
   Check (Leonardo (3) = 5, "L(3) = 5");
   Check (Leonardo (4) = 9, "L(4) = 9");
   Check (Leonardo (5) = 15, "L(5) = 15");
   Check (Leonardo (6) = 25, "L(6) = 25");
   Check (Leonardo (7) = 41, "L(7) = 41");
   Check (Leonardo (8) = 67, "L(8) = 67");
   Check (Leonardo (10) = 177, "L(10) = 177");
   Check (Leonardo (2) = Leonardo (1) + Leonardo (0) + 1,
          "recurrence L(2)=L(1)+L(0)+1");
   Check (Leonardo (9) = Leonardo (8) + Leonardo (7) + 1,
          "recurrence L(9)=L(8)+L(7)+1");
   Check (Leonardo_Raises (Max_Leonardo_Order + 1),
          "Leonardo oversize raises");

   ---------------------------------------------------------------------
   Section ("2. Empty / singleton");
   ---------------------------------------------------------------------
   declare
      Empty : Element_Array (1 .. 0);
      One   : Element_Array := [42];
      Zero  : Element_Array (0 .. -1);
   begin
      Sort (Empty);
      Check (Is_Sorted (Empty), "empty Is_Sorted");
      Check (Empty'Length = 0, "empty length preserved");
      Sort (One);
      Check (One (One'First) = 42, "singleton value preserved");
      Check (Is_Sorted (One), "singleton Is_Sorted");
      Sort (Zero);
      Check (Is_Sorted (Zero), "0-based empty Is_Sorted");
   end;

   ---------------------------------------------------------------------
   Section ("3. Already sorted (adaptive best case)");
   ---------------------------------------------------------------------
   Expect_Sorted (Sorted_Array (0), "sorted n=0");
   Expect_Sorted (Sorted_Array (1), "sorted n=1");
   Expect_Sorted (Sorted_Array (2), "sorted n=2");
   Expect_Sorted (Sorted_Array (3), "sorted n=3");
   Expect_Sorted (Sorted_Array (5), "sorted n=5");
   Expect_Sorted (Sorted_Array (8), "sorted n=8");
   Expect_Sorted (Sorted_Array (16), "sorted n=16");
   Expect_Sorted (Sorted_Array (25), "sorted n=25 = L(6)");
   Expect_Sorted (Sorted_Array (41), "sorted n=41 = L(7)");
   Expect_Sorted (Sorted_Array (100), "sorted n=100");

   ---------------------------------------------------------------------
   Section ("4. Reverse sorted");
   ---------------------------------------------------------------------
   Expect_Sorted (Reverse_Array (2), "reverse n=2");
   Expect_Sorted (Reverse_Array (3), "reverse n=3");
   Expect_Sorted (Reverse_Array (7), "reverse n=7");
   Expect_Sorted (Reverse_Array (15), "reverse n=15 = L(5)");
   Expect_Sorted (Reverse_Array (32), "reverse n=32");
   Expect_Sorted (Reverse_Array (64), "reverse n=64");
   Expect_Sorted (Reverse_Array (100), "reverse n=100");

   ---------------------------------------------------------------------
   Section ("5. Duplicates");
   ---------------------------------------------------------------------
   Expect_Sorted ([3, 1, 3, 2, 1, 2, 3], "dup mixed");
   Expect_Sorted ([5, 5, 5, 5, 5], "all equal");
   Expect_Sorted ([1, 1, 2, 2, 3, 3], "paired dups sorted");
   Expect_Sorted ([9, 8, 9, 8, 9, 8], "alternating dups");
   Expect_Sorted ([0, 0, 0, 1, 0, 0], "mostly zeros");

   ---------------------------------------------------------------------
   Section ("6. Random");
   ---------------------------------------------------------------------
   Expect_Sorted (Random_Array (2, -1000, 1000), "random n=2");
   Expect_Sorted (Random_Array (4, -1000, 1000), "random n=4");
   Expect_Sorted (Random_Array (8, -50, 50), "random n=8");
   Expect_Sorted (Random_Array (16, -50, 50), "random n=16");
   Expect_Sorted (Random_Array (31, -100, 100), "random n=31");
   Expect_Sorted (Random_Array (50, -200, 200), "random n=50");
   Expect_Sorted (Random_Array (100, -500, 500), "random n=100");
   Expect_Sorted (Random_Array (200, -1000, 1000), "random n=200");
   Expect_Sorted (Random_Array (500, -10_000, 10_000), "random n=500");

   ---------------------------------------------------------------------
   Section ("7. Index bounds / extreme values");
   ---------------------------------------------------------------------
   declare
      A : constant Element_Array (0 .. 3) := [4, 1, 3, 2];
      B : constant Element_Array (10 .. 14) := [50, 10, 40, 20, 30];
   begin
      Expect_Sorted (A, "0-based n=4");
      Expect_Sorted (B, "10-based n=5");
   end;
   Expect_Sorted ([Integer'First, Integer'Last, 0, -1],
                  "extreme Integer values");
   Expect_Sorted ([Integer'Last, Integer'First],
                  "Last then First");
   Expect_Sorted ([-1, -5, -3, -2, -4], "all negative");

   ---------------------------------------------------------------------
   Section ("8. Oversize guard");
   ---------------------------------------------------------------------
   declare
      Big : constant Element_Array (1 .. Max_Length + 1) := [others => 0];
   begin
      Check (Sort_Raises (Big), "oversize Sort raises");
   end;
   Check (not Sort_Raises (Sorted_Array (Max_Length / 1000 + 1)),
          "modest length does not raise");

   ---------------------------------------------------------------------
   Section ("9. Is_Sorted edge cases");
   ---------------------------------------------------------------------
   Check (Is_Sorted ([1, 2, 3]), "Is_Sorted ascending");
   Check (not Is_Sorted ([3, 2, 1]), "Is_Sorted rejects descending");
   Check (Is_Sorted ([2, 2, 2]), "Is_Sorted equals");
   Check (not Is_Sorted ([1, 3, 2]), "Is_Sorted rejects inversion");
   Check (Is_Sorted (Element_Array'(1 => 7)), "Is_Sorted singleton");

   ---------------------------------------------------------------------
   Section ("10. Nearly sorted / patterned");
   ---------------------------------------------------------------------
   declare
      Nearly : Element_Array := Sorted_Array (40);
      Tmp    : Integer;
   begin
      Tmp := Nearly (20);
      Nearly (20) := Nearly (21);
      Nearly (21) := Tmp;
      Expect_Sorted (Nearly, "nearly sorted swap");
   end;
   Expect_Sorted ([1, 3, 5, 7, 9, 2, 4, 6, 8, 10], "two interleaved runs");
   Expect_Sorted ([10, 1, 9, 2, 8, 3, 7, 4, 6, 5], "zigzag");

   New_Line;
   Put_Line
     ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image
      & " FAIL");
   if Fail_Count > 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
