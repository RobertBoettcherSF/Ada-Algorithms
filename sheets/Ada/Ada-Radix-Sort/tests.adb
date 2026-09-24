--  Standalone test suite for Radix_Sort (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Radix_Sort; use Radix_Sort;

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

   function Sort_Base_Raises
     (A : Element_Array; Base : Base_Range) return Boolean
   is
      T : Element_Array := A;
   begin
      Sort_Base (T, Base);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Sort_Base_Raises;

   procedure Expect_Sorted (Src : Element_Array; Label : String) is
      A : Element_Array := Copy_Of (Src);
      R : Element_Array := Copy_Of (Src);
   begin
      Sort (A);
      Reference_Sort (R);
      Check (Is_Sorted (A), Label & " Is_Sorted");
      Check (Same (A, R), Label & " matches reference");
   end Expect_Sorted;

   procedure Expect_Sorted_Base
     (Src : Element_Array; Base : Base_Range; Label : String)
   is
      A : Element_Array := Copy_Of (Src);
      R : Element_Array := Copy_Of (Src);
   begin
      Sort_Base (A, Base);
      Reference_Sort (R);
      Check (Is_Sorted (A), Label & " Is_Sorted");
      Check (Same (A, R), Label & " matches reference");
   end Expect_Sorted_Base;

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

   function Random_Nonneg
     (Len : Natural; Hi : Natural) return Element_Array
   is
      A : Element_Array (1 .. Len);
   begin
      for I in A'Range loop
         A (I) := Integer (Next_Mod (Hi + 1));
      end loop;
      return A;
   end Random_Nonneg;

begin
   ---------------------------------------------------------------------
   Section ("1. Empty and singleton");
   ---------------------------------------------------------------------
   declare
      Empty : Element_Array (1 .. 0);
      One   : Element_Array (1 .. 1) := [42];
      Zero  : Element_Array (1 .. 1) := [0];
   begin
      Sort (Empty);
      Check (Is_Sorted (Empty), "empty Is_Sorted after Sort");
      Sort (One);
      Check (One (1) = 42 and then Is_Sorted (One), "singleton unchanged");
      Sort (Zero);
      Check (Zero (1) = 0 and then Is_Sorted (Zero), "singleton zero");
   end;

   ---------------------------------------------------------------------
   Section ("2. Wikipedia LSD example");
   ---------------------------------------------------------------------
   --  [170, 45, 75, 90, 2, 802, 2, 66] → [2, 2, 45, 66, 75, 90, 170, 802]
   declare
      A : Element_Array :=
        [170, 45, 75, 90, 2, 802, 2, 66];
      Expected : constant Element_Array :=
        [2, 2, 45, 66, 75, 90, 170, 802];
   begin
      Sort (A);
      Check (Same (A, Expected), "Wikipedia LSD example exact");
      Check (Is_Sorted (A), "Wikipedia LSD Is_Sorted");
   end;

   ---------------------------------------------------------------------
   Section ("3. Already sorted / reversed / duplicates");
   ---------------------------------------------------------------------
   Expect_Sorted ([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], "already sorted");
   Expect_Sorted ([10, 9, 8, 7, 6, 5, 4, 3, 2, 1], "fully reversed");
   Expect_Sorted ([5, 5, 5, 5, 5], "all equal");
   Expect_Sorted ([3, 1, 3, 2, 1, 2, 3, 1], "many duplicates");
   Expect_Sorted ([0, 0, 0, 1, 0], "zeros mixed");

   ---------------------------------------------------------------------
   Section ("4. Single-digit and two-element");
   ---------------------------------------------------------------------
   Expect_Sorted ([9, 3, 7, 1, 0, 5, 8, 2, 4, 6], "single digits shuffled");
   Expect_Sorted ([0, 9], "two elements ascending-capable");
   Expect_Sorted ([9, 0], "two elements reversed");
   Expect_Sorted ([7, 7], "two equal");

   ---------------------------------------------------------------------
   Section ("5. Large digit counts / multi-digit keys");
   ---------------------------------------------------------------------
   Expect_Sorted
     ([999, 1000, 1, 100, 10, 0, 50_000, 49_999], "mixed digit lengths");
   Expect_Sorted
     ([1_000_000, 999_999, 2, 1_000_001], "large six/seven-digit");
   Expect_Sorted
     ([Integer'Last, 0, Integer'Last / 2, 1], "near Integer'Last");

   ---------------------------------------------------------------------
   Section ("6. Sort_Base with radix 2, 10, 256");
   ---------------------------------------------------------------------
   declare
      Src : constant Element_Array :=
        [170, 45, 75, 90, 2, 802, 2, 66, 255, 256, 0];
   begin
      Expect_Sorted_Base (Src, 2, "base 2");
      Expect_Sorted_Base (Src, 10, "base 10 via Sort_Base");
      Expect_Sorted_Base (Src, 256, "base 256");
      Expect_Sorted_Base (Src, 16, "base 16");
   end;

   ---------------------------------------------------------------------
   Section ("7. Arbitrary index bounds");
   ---------------------------------------------------------------------
   declare
      A0 : constant Element_Array (0 .. 4) :=
        [0 => 40, 1 => 10, 2 => 30, 3 => 20, 4 => 0];
      A5 : constant Element_Array (5 .. 9) :=
        [5 => 9, 6 => 1, 7 => 5, 8 => 3, 9 => 7];
      A10 : constant Element_Array (10 .. 12) :=
        [10 => 100, 11 => 0, 12 => 50];
   begin
      Expect_Sorted (A0, "0-based bounds");
      Expect_Sorted (A5, "5-based bounds");
      Expect_Sorted (A10, "10-based bounds");
   end;

   ---------------------------------------------------------------------
   Section ("8. Negatives raise Invalid_Argument");
   ---------------------------------------------------------------------
   Check (Sort_Raises ([1, -1, 2]), "negative in middle raises");
   declare
      Neg1 : constant Element_Array (1 .. 1) := [-5];
   begin
      Check (Sort_Raises (Neg1), "singleton negative raises");
   end;
   Check (Sort_Raises ([-1, -2, -3]), "all negative raises");
   Check (Sort_Base_Raises ([1, -1], 256), "Sort_Base negative raises");

   ---------------------------------------------------------------------
   Section ("9. Oversize raises Invalid_Argument");
   ---------------------------------------------------------------------
   declare
      Big : constant Element_Array (1 .. Max_Length + 1) := [others => 0];
   begin
      Check (Sort_Raises (Big), "oversize Sort raises");
      Check (Sort_Base_Raises (Big, 10), "oversize Sort_Base raises");
   end;

   ---------------------------------------------------------------------
   Section ("10. Idempotence and stability proxy");
   ---------------------------------------------------------------------
   declare
      A : Element_Array := [4, 2, 2, 8, 2, 4];
      B : Element_Array (A'Range);
   begin
      Sort (A);
      B := A;
      Sort (A);
      Check (Same (A, B), "Sort is idempotent");
      Check (Is_Sorted (A), "idempotent result still sorted");
   end;

   --  Stability proxy: full-integer sort of encoded (key, tag) pairs
   --  must match the stable insertion-sort reference.
   declare
      A : Element_Array :=
        [7 * 1000 + 1, 3 * 1000 + 2, 7 * 1000 + 3, 3 * 1000 + 4];
      R : Element_Array := Copy_Of (A);
   begin
      Sort (A);
      Reference_Sort (R);
      Check (Same (A, R), "encoded pairs match stable reference");
   end;

   ---------------------------------------------------------------------
   Section ("11. Random nonnegative vs reference");
   ---------------------------------------------------------------------
   declare
      Lengths : constant array (Positive range <>) of Natural :=
        [2, 3, 5, 8, 16, 32, 50, 100];
   begin
      for L of Lengths loop
         declare
            Src : constant Element_Array := Random_Nonneg (L, 10_000);
         begin
            Expect_Sorted (Src, "random len=" & L'Image);
         end;
      end loop;
   end;

   --  Random with Sort_Base 256 and 2
   declare
      Src : constant Element_Array := Random_Nonneg (40, 50_000);
   begin
      Expect_Sorted_Base (Src, 256, "random base-256");
      Expect_Sorted_Base (Src, 2, "random base-2");
   end;

   ---------------------------------------------------------------------
   Section ("12. All zeros / extremes");
   ---------------------------------------------------------------------
   declare
      Z : Element_Array (1 .. 20) := [others => 0];
      Edge : Element_Array (1 .. 1) := [Integer'Last];
   begin
      Sort (Z);
      Check (Is_Sorted (Z), "all zeros sorted");
      Sort (Edge);
      Check (Edge (1) = Integer'Last, "Integer'Last singleton");
   end;

   declare
      A : Element_Array (1 .. 200) := [others => 0];
   begin
      for I in A'Range loop
         A (I) := Integer (Next_Mod (1000));
      end loop;
      Sort (A);
      Check (Is_Sorted (A), "len=200 Sort Is_Sorted");
   end;

   ---------------------------------------------------------------------
   Section ("13. Sort vs Sort_Base(10) agreement");
   ---------------------------------------------------------------------
   declare
      Src : constant Element_Array :=
        [42, 0, 17, 99, 3, 256, 1000, 7];
      A : Element_Array := Copy_Of (Src);
      B : Element_Array := Copy_Of (Src);
   begin
      Sort (A);
      Sort_Base (B, 10);
      Check (Same (A, B), "Sort equals Sort_Base(,10)");
   end;

   New_Line;
   Put_Line
     ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image & " FAIL");

   if Fail_Count /= 0 then
      raise Program_Error with "test failures present";
   end if;
end Tests;
