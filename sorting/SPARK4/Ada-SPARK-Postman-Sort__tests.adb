--  Standalone test suite for Postman_Sort (SPARK port).
--  Preconditions replace exceptions; only valid call paths are exercised.
--  A'First is always 1; Max_N = 64; nonnegative keys only (Keys_Ok).
--  Sortedness is proved by SPARK; multiset / permutation equality is
--  checked here.

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Postman_Sort; use Postman_Sort;

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
   Put_Line ("Postman_Sort (SPARK) tests");
   Put_Line ("==========================");

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
   Expect_Sorted ([42], "singleton via Expect");

   ---------------------------------------------------------------------
   Section ("2. Classic MSD / postman examples");
   ---------------------------------------------------------------------
   --  Same numeric result as LSD on nonnegative ints with leading-zero pad.
   declare
      A : Element_Array :=
        [170, 45, 75, 90, 2, 802, 2, 66];
      Expected : constant Element_Array :=
        [2, 2, 45, 66, 75, 90, 170, 802];
   begin
      Check (Keys_Ok (A), "classic Keys_Ok");
      Sort (A);
      Check (Same (A, Expected), "classic multi-digit exact");
      Check (Boo (Is_Sorted (A)), "classic multi-digit Is_Sorted");
      Check (Is_Permutation (A, [170, 45, 75, 90, 2, 802, 2, 66]),
             "classic permutation");
   end;

   --  Short-before-long numeric order (MSD with padded digits).
   declare
      A : Element_Array := [10, 2, 1, 11, 9];
      Expected : constant Element_Array := [1, 2, 9, 10, 11];
   begin
      Sort (A);
      Check (Same (A, Expected), "variable length numeric order");
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
   Expect_Sorted ([1, 0], "two swapped with zero");
   Expect_Sorted ([3, 1, 2], "tiny 3");

   ---------------------------------------------------------------------
   Section ("5. Large digit counts / multi-digit keys");
   ---------------------------------------------------------------------
   Expect_Sorted
     ([999, 1000, 1, 100, 10, 0, 50_000, 49_999], "mixed digit lengths");
   Expect_Sorted
     ([1_000_000, 999_999, 2, 1_000_001], "large six/seven-digit");
   Expect_Sorted
     ([Integer'Last, 0, Integer'Last / 2, 1], "near Integer'Last");
   Expect_Sorted ([8, 80, 800, 8000, 7], "powers-of-ten lengths");
   Expect_Sorted ([111, 11, 1, 222, 22, 2], "repeated digits");
   Expect_Sorted ([200, 20, 2, 210, 21, 12], "shared prefixes");

   ---------------------------------------------------------------------
   Section ("6. Postal / pigeonhole distribution");
   ---------------------------------------------------------------------
   --  Keys that share MSD then diverge (like ZIP / postal prefixes).
   Expect_Sorted
     ([94105, 94103, 10001, 10011, 90210, 94107], "postal-prefix style");
   Expect_Sorted
     ([100, 101, 110, 111, 1, 10, 11], "shared prefixes base-10");
   Expect_Sorted ([100, 101, 110, 111, 001, 010, 011], "leading-zero nums");
   Expect_Sorted
     ([94105, 94103, 94107, 94102, 94110], "same 3-digit ZIP prefix");

   ---------------------------------------------------------------------
   Section ("7. In_Bounds / Keys_Ok / Max_N shape");
   ---------------------------------------------------------------------
   declare
      Ok    : constant Element_Array := [1, 2, 3];
      Bad   : constant Element_Array := [3, 1, 2];
      Neg   : constant Element_Array := [1, -1, 2];
      Neg1  : constant Element_Array := [-5];
      Empty : Element_Array (1 .. 0);
      Full  : constant Element_Array (1 .. Max_N) := [others => 0];
   begin
      Check (Boo (Is_Sorted (Ok)), "Is_Sorted true on sorted");
      Check (not Boo (Is_Sorted (Bad)), "Is_Sorted false on unsorted");
      Check (In_Bounds (Ok), "In_Bounds small");
      Check (In_Bounds (Empty), "In_Bounds empty");
      Check (In_Bounds (Full), "In_Bounds Max_N");
      Check (Keys_Ok (Ok), "Keys_Ok tiny");
      Check (Keys_Ok (Empty), "Keys_Ok empty");
      Check (Keys_Ok (Full), "Keys_Ok all zeros Max_N");
      Check (not Keys_Ok (Neg), "Keys_Ok false on mixed negative");
      Check (not Keys_Ok (Neg1), "Keys_Ok false on singleton negative");
      Check (not Keys_Ok ([-1, -2, -3]), "Keys_Ok false all negative");
      Check (Keys_Ok ([0, Integer'Last]), "Keys_Ok min/max nonnegative");
   end;

   declare
      Cap : Element_Array (1 .. Max_N);
   begin
      for I in Cap'Range loop
         Cap (I) := Max_N - I;
      end loop;
      Expect_Sorted (Cap, "Max_N reverse 0..63");
   end;

   ---------------------------------------------------------------------
   Section ("8. Idempotence and stability proxy");
   ---------------------------------------------------------------------
   declare
      A : Element_Array := [4, 2, 2, 8, 2, 4];
      B : Element_Array (A'Range);
   begin
      Sort (A);
      B := A;
      Sort (A);
      Check (Same (A, B), "Sort is idempotent");
      Check (Boo (Is_Sorted (A)), "idempotent result still sorted");
   end;

   --  Stability proxy: encoded (key, tag) pairs must match stable reference.
   declare
      A : Element_Array :=
        [7 * 1000 + 1, 3 * 1000 + 2, 7 * 1000 + 3, 3 * 1000 + 4];
      R : Element_Array := Copy_Of (A);
      O : constant Element_Array := Copy_Of (A);
   begin
      Sort (A);
      Reference_Sort (R);
      Check (Same (A, R), "encoded pairs match stable reference");
      Check (Is_Permutation (A, O), "encoded pairs permutation");
   end;

   ---------------------------------------------------------------------
   Section ("9. Random nonnegative vs reference");
   ---------------------------------------------------------------------
   Expect_Sorted (Random_Nonneg (20, 9), "random n=20 range 0..9");
   Expect_Sorted (Random_Nonneg (32, 99), "random n=32 range 0..99");
   Expect_Sorted (Random_Nonneg (50, 10_000), "random n=50 range 0..10000");
   Expect_Sorted (Random_Nonneg (Max_N, 255), "random Max_N range 0..255");
   Expect_Sorted (Random_Nonneg (16, 0), "random all-zero span");
   Expect_Sorted (Random_Nonneg (40, 1), "random 0..1");
   Expect_Sorted (Random_Nonneg (25, 1_000_000), "random n=25 large keys");
   Expect_Sorted (Random_Nonneg (7, 5), "random n=7 tiny");
   Expect_Sorted (Random_Nonneg (12, 100), "random n=12 mid");
   Expect_Sorted (Random_Nonneg (63, 999), "random n=63 mid");

   ---------------------------------------------------------------------
   Section ("10. All zeros / extremes / edge patterns");
   ---------------------------------------------------------------------
   declare
      Z : Element_Array (1 .. 20) := [others => 0];
      Edge : Element_Array (1 .. 1) := [Integer'Last];
   begin
      Sort (Z);
      Check (Boo (Is_Sorted (Z)), "all zeros sorted");
      Sort (Edge);
      Check (Int (Edge (1)) = Integer'Last, "Integer'Last singleton");
   end;
   Expect_Sorted ([0, 0, 0, 0], "all zeros via Expect");
   Expect_Sorted ([Integer'Last, Integer'Last], "two Integer'Last");
   Expect_Sorted ([0, Integer'Last], "min max pair");
   Expect_Sorted ([Integer'Last, 0], "max min pair");
   Expect_Sorted ([1, 2], "two ascending");
   Expect_Sorted ([2, 1], "two descending");
   Expect_Sorted ([1, 2, 3, 5, 4], "almost sorted");
   Expect_Sorted ([10, 20, 30, 40, 50, 5], "gapped then low");
   Expect_Sorted
     ([100, 1, 99, 2, 98, 3, 97, 4, 96, 5], "sawtooth");
   Expect_Sorted
     ([1, 10, 2, 20, 3, 30, 4, 40], "two interleaved runs");
   Expect_Sorted ([15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1],
                  "reverse 15");

   declare
      A : Element_Array (1 .. 32);
   begin
      for I in A'Range loop
         A (I) := 33 - I;
      end loop;
      Expect_Sorted (A, "reverse n=32");
   end;

   declare
      A : Element_Array (1 .. 17);
   begin
      for I in A'Range loop
         A (I) := 18 - I;
      end loop;
      Expect_Sorted (A, "odd length reverse 17");
   end;

   ---------------------------------------------------------------------
   Section ("11. Is_Sorted predicate");
   ---------------------------------------------------------------------
   Check (Boo (Is_Sorted ([1, 2, 3, 4])), "ascending true");
   Check (Boo (Is_Sorted ([1, 1, 2, 2])), "nondecreasing true");
   Check (not Boo (Is_Sorted ([1, 3, 2])), "inversion false");
   Check (not Boo (Is_Sorted ([5, 4, 3])), "reverse false");
   Check (Boo (Is_Sorted ([7])), "singleton true");
   Check (Boo (Is_Sorted ([0, 0, 0])), "zeros nondecreasing");
   Check (not Boo (Is_Sorted ([0, 2, 1])), "zero then inversion false");
   Check (Boo (Is_Sorted ([0, 8, Integer'Last])), "min mid max ascending");
   Check (not Boo (Is_Sorted ([Integer'Last, 0])), "max then min false");
   declare
      E : Element_Array (1 .. 0);
   begin
      Check (Boo (Is_Sorted (E)), "empty true");
   end;

   New_Line;
   Put_Line ("Results: "
             & Natural'Image (Pass_Count) & " PASS,"
             & Natural'Image (Fail_Count) & " FAIL");
   if Fail_Count > 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
