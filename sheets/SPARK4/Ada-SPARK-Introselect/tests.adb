--  Standalone test suite for Introselect (SPARK port).
--  Preconditions replace exceptions; only valid call paths are exercised.
--  A'First is always 1; Max_N = 64. Is_Kth_Partitioned is proved by SPARK;
--  order-statistic agreement vs sorted copy and multiset / permutation
--  equality after Select_Kth are checked here.

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Introselect; use Introselect;

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

   function Reference_Kth (A : Element_Array; K : Positive) return Integer is
      C : Element_Array := A;
   begin
      Reference_Sort (C);
      return C (C'First + (K - 1));
   end Reference_Kth;

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

   procedure Expect_Kth (Src : Element_Array; K : Positive; Label : String) is
      A   : Element_Array := Copy_Of (Src);
      O   : constant Element_Array := Copy_Of (Src);
      Exp : constant Integer := Reference_Kth (Src, K);
      Idx : constant Positive := A'First + (K - 1);
   begin
      Select_Kth (A, K);
      Check (Int (A (Idx)) = Exp, Label & " Select_Kth value");
      Check (Boo (Is_Kth_Partitioned (A, K)), Label & " Is_Kth_Partitioned");
      Check (Is_Permutation (A, O), Label & " permutation");
   end Expect_Kth;

   procedure Expect_Kth_Copy
     (Src : Element_Array; K : Positive; Label : String)
   is
      Before : constant Element_Array := Copy_Of (Src);
      Got    : constant Integer := Select_Kth_Copy (Src, K);
      Exp    : constant Integer := Reference_Kth (Src, K);
   begin
      Check (Int (Got) = Exp, Label & " Select_Kth_Copy");
      Check (Same (Src, Before), Label & " Copy leaves original unchanged");
   end Expect_Kth_Copy;

   procedure Expect_Median (Src : Element_Array; Label : String) is
      N   : constant Positive := Src'Length;
      K   : Positive;
      Got : constant Integer := Median (Src);
      Exp : Integer;
      Before : constant Element_Array := Copy_Of (Src);
   begin
      if N rem 2 = 1 then
         K := (N + 1) / 2;
      else
         K := N / 2;
      end if;
      Exp := Reference_Kth (Src, K);
      Check (Int (Got) = Exp, Label & " Median");
      Check (Same (Src, Before), Label & " Median leaves original unchanged");
   end Expect_Median;

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
   Put_Line ("Introselect (SPARK) tests");
   Put_Line ("==========================");

   ---------------------------------------------------------------------
   Section ("1. Singleton and tiny");
   ---------------------------------------------------------------------
   declare
      One : Element_Array := [1 => 42];
      Neg : Element_Array := [1 => -7];
      Two : constant Element_Array := [5, 1];
   begin
      Select_Kth (One, 1);
      Check (Int (One (One'First)) = 42, "singleton k=1");
      Check (Boo (Is_Kth_Partitioned (One, 1)), "singleton partitioned");
      Select_Kth (Neg, 1);
      Check (Int (Neg (Neg'First)) = -7, "negative singleton");
      Expect_Kth ([5, 1], 1, "two min");
      Expect_Kth ([5, 1], 2, "two max");
      Expect_Kth_Copy (Two, 1, "two copy min");
      Expect_Median ([5, 1], "two lower-middle");
      Expect_Median ([42], "singleton Median");
   end;

   ---------------------------------------------------------------------
   Section ("2. Min, max, median on small arrays");
   ---------------------------------------------------------------------
   declare
      A : constant Element_Array := [9, 3, 7, 1, 5, 8, 2];
   begin
      Expect_Kth (A, 1, "small min");
      Expect_Kth (A, 7, "small max");
      Expect_Kth (A, 4, "small median rank");
      Expect_Median (A, "small odd Median");
      Expect_Kth_Copy (A, 3, "small copy k=3");
      Expect_Kth (A, 2, "small k=2");
      Expect_Kth (A, 5, "small k=5");
      Expect_Kth (A, 6, "small k=6");
   end;

   ---------------------------------------------------------------------
   Section ("3. Even length — lower middle median");
   ---------------------------------------------------------------------
   declare
      E : constant Element_Array := [6, 1, 4, 2, 5, 3];
   begin
      Expect_Median (E, "even n=6 lower middle");
      Expect_Kth (E, 3, "even k=3");
      Expect_Kth (E, 4, "even upper middle k=4");
      Expect_Kth (E, 1, "even min");
      Expect_Kth (E, 6, "even max");
      Expect_Kth_Copy (E, 2, "even copy k=2");
      Expect_Kth_Copy (E, 5, "even copy k=5");
   end;

   ---------------------------------------------------------------------
   Section ("4. Duplicates");
   ---------------------------------------------------------------------
   declare
      D  : constant Element_Array := [5, 1, 5, 2, 5, 3, 5];
      Eq : constant Element_Array := [7, 7, 7, 7, 7];
   begin
      Expect_Kth (D, 1, "dup min");
      Expect_Kth (D, 7, "dup max");
      Expect_Kth (D, 4, "dup first 5");
      Expect_Kth (D, 5, "dup second 5");
      Expect_Kth (D, 6, "dup third 5");
      Expect_Median (D, "dup Median");
      Expect_Kth (Eq, 1, "all-equal min");
      Expect_Kth (Eq, 3, "all-equal mid");
      Expect_Kth (Eq, 5, "all-equal max");
      Expect_Median (Eq, "all-equal Median");
      Expect_Kth_Copy (D, 2, "dup copy");
      Expect_Kth_Copy (Eq, 4, "all-equal copy");
   end;

   ---------------------------------------------------------------------
   Section ("5. Already sorted / reverse / nearly sorted");
   ---------------------------------------------------------------------
   declare
      S : constant Element_Array := [1, 2, 3, 4, 5, 6, 8, 9, 10];
      R : constant Element_Array := [10, 9, 8, 7, 6, 5, 4, 3, 2, 1];
      N : constant Element_Array := [1, 2, 3, 5, 4, 6, 7];
   begin
      Expect_Kth (S, 1, "sorted min");
      Expect_Kth (S, 5, "sorted mid");
      Expect_Kth (S, 9, "sorted max");
      Expect_Median (S, "sorted Median odd");
      Expect_Kth (R, 1, "reverse min");
      Expect_Kth (R, 5, "reverse mid");
      Expect_Kth (R, 10, "reverse max");
      Expect_Median (R, "reverse Median even");
      Expect_Kth (N, 4, "nearly k=4");
      Expect_Kth_Copy (R, 5, "reverse copy k=5");
      Expect_Kth_Copy (S, 3, "sorted copy k=3");
   end;

   ---------------------------------------------------------------------
   Section ("6. Negatives, zero, mixed, extremes");
   ---------------------------------------------------------------------
   declare
      M : constant Element_Array := [-5, 0, 3, -2, 1, -8, 4];
   begin
      Expect_Kth (M, 1, "mixed min");
      Expect_Kth (M, 4, "mixed median rank");
      Expect_Kth (M, 7, "mixed max");
      Expect_Median (M, "mixed Median");
      Expect_Kth ([0, 0, 0], 2, "zeros k=2");
      Expect_Kth ([-1, -3, -2], 2, "all neg mid");
      Expect_Kth ([-10, 10, -5, 5, 0], 1, "signed min");
      Expect_Kth ([-10, 10, -5, 5, 0], 5, "signed max");
      Expect_Median ([-10, 10, -5, 5, 0], "signed Median");
      Expect_Kth_Copy (M, 2, "mixed copy");
      Expect_Kth ([Integer'First, 0, Integer'Last], 2, "extremes mid");
      Expect_Kth ([Integer'Last, Integer'First], 1, "two extremes min");
      Expect_Kth ([Integer'Last, Integer'First], 2, "two extremes max");
   end;

   ---------------------------------------------------------------------
   Section ("7. Wikipedia-style examples");
   ---------------------------------------------------------------------
   Expect_Kth ([9, 3, 2, 7, 1, 8, 5], 3, "wiki-ish 3rd");
   Expect_Kth ([9, 3, 2, 7, 1, 8, 5], 1, "wiki-ish min");
   Expect_Kth ([9, 3, 2, 7, 1, 8, 5], 7, "wiki-ish max");
   Expect_Median ([9, 3, 2, 7, 1, 8, 5], "wiki-ish Median");
   Expect_Kth_Copy ([9, 3, 2, 7, 1, 8, 5], 4, "wiki-ish copy median");

   ---------------------------------------------------------------------
   Section ("8. Partition invariant after Select_Kth");
   ---------------------------------------------------------------------
   Expect_Kth ([8, 1, 6, 3, 9, 2, 7, 4, 5], 4, "inv k=4");
   Expect_Kth ([8, 1, 6, 3, 9, 2, 7, 4, 5], 1, "inv k=1");
   Expect_Kth ([8, 1, 6, 3, 9, 2, 7, 4, 5], 9, "inv k=9");
   Expect_Kth ([5, 5, 5, 5, 5], 3, "inv all-equal");
   Expect_Kth ([-3, 0, 2, -1, 4], 2, "inv mixed");

   ---------------------------------------------------------------------
   Section ("9. In_Bounds / Max_N shape");
   ---------------------------------------------------------------------
   declare
      Empty : Element_Array (1 .. 0);
      Cap   : Element_Array (1 .. Max_N) := [others => 0];
   begin
      Check (In_Bounds (Empty), "empty In_Bounds");
      Check (Nat (Empty'Length) = 0, "empty length 0");
      Check (In_Bounds (Cap), "Max_N In_Bounds");
      for I in Cap'Range loop
         Cap (I) := Integer (Max_N + 1 - I);
      end loop;
      Expect_Kth (Cap, 1, "reverse Max_N min");
      Expect_Kth (Cap, Max_N / 2, "reverse Max_N mid");
      Expect_Kth (Cap, Max_N, "reverse Max_N max");
      Expect_Median (Cap, "reverse Max_N Median");
   end;

   ---------------------------------------------------------------------
   Section ("10. All permutations of {1,2,3}");
   ---------------------------------------------------------------------
   declare
      P3 : constant array (Positive range <>) of Element_Array (1 .. 3) :=
        [[1, 2, 3], [1, 3, 2], [2, 1, 3], [2, 3, 1], [3, 1, 2], [3, 2, 1]];
   begin
      for Pi in P3'Range loop
         for K in 1 .. 3 loop
            Expect_Kth (P3 (Pi), K, "perm3#" & Pi'Image & " k=" & K'Image);
         end loop;
         Expect_Median (P3 (Pi), "perm3#" & Pi'Image);
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("11. All permutations of {0,1,2,3}");
   ---------------------------------------------------------------------
   declare
      P4 : constant array (Positive range <>) of Element_Array (1 .. 4) :=
        [[0, 1, 2, 3], [0, 1, 3, 2], [0, 2, 1, 3], [0, 2, 3, 1],
         [0, 3, 1, 2], [0, 3, 2, 1], [1, 0, 2, 3], [1, 0, 3, 2],
         [1, 2, 0, 3], [1, 2, 3, 0], [1, 3, 0, 2], [1, 3, 2, 0],
         [2, 0, 1, 3], [2, 0, 3, 1], [2, 1, 0, 3], [2, 1, 3, 0],
         [2, 3, 0, 1], [2, 3, 1, 0], [3, 0, 1, 2], [3, 0, 2, 1],
         [3, 1, 0, 2], [3, 1, 2, 0], [3, 2, 0, 1], [3, 2, 1, 0]];
   begin
      for Pi in P4'Range loop
         for K in 1 .. 4 loop
            Expect_Kth (P4 (Pi), K, "perm4#" & Pi'Image & " k=" & K'Image);
         end loop;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("12. Two-element exhaustive");
   ---------------------------------------------------------------------
   Expect_Kth ([1, 2], 1, "asc2 k1");
   Expect_Kth ([1, 2], 2, "asc2 k2");
   Expect_Kth ([2, 1], 1, "desc2 k1");
   Expect_Kth ([2, 1], 2, "desc2 k2");
   Expect_Kth ([7, 7], 1, "eq2 k1");
   Expect_Kth ([7, 7], 2, "eq2 k2");
   Expect_Median ([1, 2], "asc2 Median");
   Expect_Median ([2, 1], "desc2 Median");
   Expect_Kth_Copy ([2, 1], 1, "desc2 copy");

   ---------------------------------------------------------------------
   Section ("13. Random vs sorted reference");
   ---------------------------------------------------------------------
   declare
      Lens : constant array (Positive range <>) of Positive :=
        [5, 10, 17, 32, 50, 64];
   begin
      for L of Lens loop
         declare
            A : constant Element_Array := Random_Array (L, -50, 50);
         begin
            Expect_Kth (A, 1, "rand n=" & L'Image & " min");
            Expect_Kth (A, L, "rand n=" & L'Image & " max");
            Expect_Kth (A, (L + 1) / 2, "rand n=" & L'Image & " mid");
            Expect_Kth_Copy (A, L / 2 + 1, "rand n=" & L'Image & " copy");
            Expect_Median (A, "rand n=" & L'Image & " Median");
         end;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("14. All ranks on small permutation");
   ---------------------------------------------------------------------
   declare
      P : constant Element_Array := [4, 1, 3, 2, 0];
   begin
      for K in 1 .. 5 loop
         Expect_Kth (P, K, "perm k=" & K'Image);
         Expect_Kth_Copy (P, K, "perm copy k=" & K'Image);
      end loop;
      Expect_Median (P, "perm Median");
   end;

   ---------------------------------------------------------------------
   Section ("15. Select_Kth_Copy / Median leave original unchanged");
   ---------------------------------------------------------------------
   declare
      Orig : constant Element_Array := [9, 1, 8, 2, 7, 3, 6, 4, 5];
      Snap : constant Element_Array := Copy_Of (Orig);
      V    : Integer;
      pragma Unreferenced (V);
   begin
      for K in 1 .. Orig'Length loop
         V := Select_Kth_Copy (Orig, K);
         Check (Same (Orig, Snap),
                "unchanged after copy k=" & K'Image);
      end loop;
      V := Median (Orig);
      Check (Same (Orig, Snap), "unchanged after Median");
   end;

   ---------------------------------------------------------------------
   Section ("16. Is_Kth_Partitioned helper");
   ---------------------------------------------------------------------
   declare
      Good : constant Element_Array := [1, 2, 5, 8, 9];
      Bad  : Element_Array := [9, 2, 5, 1, 8];
   begin
      Check (Boo (Is_Kth_Partitioned (Good, 3)), "sorted is partitioned at 3");
      Check (not Boo (Is_Kth_Partitioned (Bad, 3)), "unsorted not partitioned");
      Select_Kth (Bad, 3);
      Check (Boo (Is_Kth_Partitioned (Bad, 3)), "after select partitioned");
   end;


   ---------------------------------------------------------------------
   Section ("17. Depth-budget / MoM-capable sizes");
   ---------------------------------------------------------------------
   declare
      A31 : constant Element_Array := Random_Array (31, -100, 100);
      A63 : constant Element_Array := Random_Array (63, -200, 200);
      Asc : Element_Array (1 .. Max_N);
      Desc : Element_Array (1 .. Max_N);
   begin
      for K in 1 .. 31 loop
         Expect_Kth (A31, K, "n=31 k=" & K'Image);
      end loop;
      Expect_Median (A31, "n=31 Median");
      Expect_Kth (A63, 1, "n=63 min");
      Expect_Kth (A63, 32, "n=63 mid");
      Expect_Kth (A63, 63, "n=63 max");
      Expect_Median (A63, "n=63 Median");
      Expect_Kth_Copy (A63, 16, "n=63 copy");
      for I in Asc'Range loop
         Asc (I) := I;
         Desc (I) := Max_N + 1 - I;
      end loop;
      Expect_Kth (Asc, 1, "asc64 min");
      Expect_Kth (Asc, 32, "asc64 mid");
      Expect_Kth (Asc, Max_N, "asc64 max");
      Expect_Median (Asc, "asc64 Median");
      Expect_Kth (Desc, 1, "desc64 min");
      Expect_Kth (Desc, 32, "desc64 mid");
      Expect_Kth (Desc, Max_N, "desc64 max");
      Expect_Median (Desc, "desc64 Median");
      Expect_Kth_Copy (Desc, 20, "desc64 copy");
   end;

   New_Line;
   Put_Line
     ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image & " FAIL");

   if Fail_Count > 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
