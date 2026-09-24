--  Standalone test suite for Bitonic_Sorter (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Bitonic_Sorter; use Bitonic_Sorter;

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

   function Compare_Swap_Raises
     (A : Element_Array; I, J : Natural; Asc : Boolean) return Boolean
   is
      T : Element_Array := A;
   begin
      Compare_Swap (T, I, J, Asc);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Compare_Swap_Raises;

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

begin
   ---------------------------------------------------------------------
   Section ("1. Empty and singleton");
   ---------------------------------------------------------------------
   declare
      E : Element_Array (1 .. 0);
      S : Element_Array (1 .. 1) := [42];
      Z : Element_Array (1 .. 1) := [0];
   begin
      Check (Is_Sorted (E), "empty Is_Sorted");
      Sort (E);
      Check (Is_Sorted (E), "empty Sort no-op");
      Check (Is_Sorted (S), "singleton Is_Sorted");
      Sort (S);
      Check (S (1) = 42, "singleton Sort preserves");
      Sort (Z);
      Check (Z (1) = 0, "singleton zero preserved");
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

   ---------------------------------------------------------------------
   Section ("3. Already sorted / reverse / duplicates");
   ---------------------------------------------------------------------
   Expect_Sorted ([1, 2, 3, 4, 5, 6, 7, 8], "already sorted n=8");
   Expect_Sorted ([1, 1, 1, 1], "all equal n=4");
   Expect_Sorted ([5, 5, 3, 3, 5, 1, 1, 3], "duplicates n=8");
   Expect_Sorted ([-3, -1, 0, 2], "negatives sorted n=4");
   Expect_Sorted ([0, -5, 10, -5], "negatives mixed n=4");

   ---------------------------------------------------------------------
   Section ("4. Padding (non-power-of-two lengths)");
   ---------------------------------------------------------------------
   Check (Next_Power_Of_Two (3) = 4, "pad 3 → 4");
   Check (Next_Power_Of_Two (5) = 8, "pad 5 → 8");
   Check (Next_Power_Of_Two (7) = 8, "pad 7 → 8");
   Check (Next_Power_Of_Two (9) = 16, "pad 9 → 16");
   Check (not Is_Power_Of_Two (0), "0 not power of two");
   Check (Is_Power_Of_Two (1), "1 is power of two");
   Check (Is_Power_Of_Two (8), "8 is power of two");
   Check (not Is_Power_Of_Two (6), "6 not power of two");
   Expect_Sorted ([3, 1, 2], "n=3 padded");
   Expect_Sorted ([5, 4, 3, 2, 1], "n=5 reverse padded");
   Expect_Sorted ([9, 1, 8, 2, 7, 3, 6], "n=7 shuffled padded");
   Expect_Sorted
     ([10, 9, 8, 7, 6, 5, 4, 3, 2], "n=9 reverse padded");
   Expect_Sorted (Random_Array (12, -20, 20), "n=12 random padded");
   Expect_Sorted (Random_Array (15, 0, 100), "n=15 random padded");
   Expect_Sorted ([1, 2, 3], "n=3 already sorted padded");
   --  Sentinel value Integer'Last present in data must still sort.
   Expect_Sorted
     ([Integer'Last, 1, 0], "n=3 with Integer'Last data");
   Expect_Sorted
     ([5, Integer'Last, 3, Integer'Last, 1],
      "n=5 with Integer'Last data");

   ---------------------------------------------------------------------
   Section ("5. Compare_Swap");
   ---------------------------------------------------------------------
   declare
      A : Element_Array (1 .. 3) := [5, 1, 3];
      B : Element_Array (1 .. 3) := [1, 5, 3];
   begin
      Compare_Swap (A, 1, 2, True);
      Check (A (1) = 1 and then A (2) = 5, "Compare_Swap ascending");
      Compare_Swap (B, 1, 2, False);
      Check (B (1) = 5 and then B (2) = 1, "Compare_Swap descending");
      Check (Compare_Swap_Raises (A, 0, 1, True),
             "Compare_Swap bad index raises");
      Check (Compare_Swap_Raises (A, 1, 99, True),
             "Compare_Swap high index raises");
   end;

   ---------------------------------------------------------------------
   Section ("6. Non-1-based bounds");
   ---------------------------------------------------------------------
   declare
      A : constant Element_Array (0 .. 3) := [4, 3, 2, 1];
      B : constant Element_Array (10 .. 14) := [5, 1, 4, 2, 3];
   begin
      Expect_Sorted (A, "0-based n=4");
      Expect_Sorted (B, "10-based n=5 padded");
   end;

   ---------------------------------------------------------------------
   Section ("7. Oversize guard");
   ---------------------------------------------------------------------
   declare
      Big : constant Element_Array (1 .. Max_Length + 1) := [others => 0];
   begin
      Check (Sort_Raises (Big), "oversize Sort raises");
   end;

   ---------------------------------------------------------------------
   Section ("8. More random / edge");
   ---------------------------------------------------------------------
   Expect_Sorted (Random_Array (2, -1000, 1000), "random n=2");
   Expect_Sorted (Random_Array (4, -1000, 1000), "random n=4");
   Expect_Sorted (Random_Array (8, -1000, 1000), "random n=8");
   Expect_Sorted (Random_Array (16, -1000, 1000), "random n=16");
   Expect_Sorted (Random_Array (6, -50, 50), "random n=6 padded");
   Expect_Sorted (Random_Array (10, -50, 50), "random n=10 padded");
   Expect_Sorted (Random_Array (24, -50, 50), "random n=24 padded");
   Expect_Sorted ([Integer'First, Integer'Last, 0, -1],
                  "extreme Integer values n=4");
   Expect_Sorted ([Integer'First, Integer'First + 1, -1],
                  "extreme n=3 padded");
   Check (Next_Power_Of_Two (1) = 1, "next pot 1");
   Check (Next_Power_Of_Two (8) = 8, "next pot 8 identity");
   Check (Next_Power_Of_Two (0) = 1, "next pot 0 → 1");

   New_Line;
   Put_Line
     ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image
      & " FAIL");
   if Fail_Count > 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
