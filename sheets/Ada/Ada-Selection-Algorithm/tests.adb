--  Standalone test suite for Selection_Algorithm (main program).

pragma Ada_2022;

with Ada.Text_IO;          use Ada.Text_IO;
with Selection_Algorithm;  use Selection_Algorithm;

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

   --  Naive sort-based reference (insertion sort) — tests only, not exported.
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

   function Copy_Of (A : Element_Array) return Element_Array is
   begin
      return Element_Array'(A);
   end Copy_Of;

   function Select_Raises (A : Element_Array; K : Positive) return Boolean is
      T : Element_Array := A;
      X : Integer;
      pragma Unreferenced (X);
   begin
      X := Select_Kth (T, K);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Select_Raises;

   function Copy_Raises (A : Element_Array; K : Positive) return Boolean is
      X : Integer;
      pragma Unreferenced (X);
   begin
      X := Select_Kth_Copy (A, K);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Copy_Raises;

   function Median_Raises (A : Element_Array) return Boolean is
      T : Element_Array := A;
      X : Integer;
      pragma Unreferenced (X);
   begin
      X := Median (T);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Median_Raises;

   procedure Expect_Kth (Src : Element_Array; K : Positive; Label : String) is
      A   : Element_Array := Copy_Of (Src);
      Got : constant Integer := Select_Kth (A, K);
      Exp : constant Integer := Reference_Kth (Src, K);
   begin
      Check (Got = Exp, Label & " Select_Kth");
   end Expect_Kth;

   procedure Expect_Kth_Copy
     (Src : Element_Array; K : Positive; Label : String)
   is
      Before : constant Element_Array := Copy_Of (Src);
      Got    : constant Integer := Select_Kth_Copy (Src, K);
      Exp    : constant Integer := Reference_Kth (Src, K);
      Unchanged : Boolean := True;
   begin
      Check (Got = Exp, Label & " Select_Kth_Copy");
      for I in Src'Range loop
         if Src (I) /= Before (I) then
            Unchanged := False;
         end if;
      end loop;
      Check (Unchanged, Label & " Copy leaves original unchanged");
   end Expect_Kth_Copy;

   procedure Expect_Median (Src : Element_Array; Label : String) is
      A   : Element_Array := Copy_Of (Src);
      N   : constant Natural := Src'Length;
      K   : Positive;
      Got : Integer;
      Exp : Integer;
   begin
      if N rem 2 = 1 then
         K := (N + 1) / 2;
      else
         K := N / 2;
      end if;
      Got := Median (A);
      Exp := Reference_Kth (Src, K);
      Check (Got = Exp, Label & " Median");
   end Expect_Median;

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
   Section ("1. Singleton and tiny");
   ---------------------------------------------------------------------
   declare
      One : Element_Array := [42];
      Neg : Element_Array := [-7];
      Two : constant Element_Array := [5, 1];
   begin
      Check (Select_Kth (One, 1) = 42, "singleton k=1");
      Check (Select_Kth (Neg, 1) = -7, "negative singleton");
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
      --  Sorted: 1,2,3,5,7,8,9  n=7 odd → median rank 4 = 5
   begin
      Expect_Kth (A, 1, "small min");
      Expect_Kth (A, 7, "small max");
      Expect_Kth (A, 4, "small median rank");
      Expect_Median (A, "small odd Median");
      Expect_Kth_Copy (A, 3, "small copy k=3");
   end;

   ---------------------------------------------------------------------
   Section ("3. Even length — lower middle median");
   ---------------------------------------------------------------------
   declare
      --  Sorted: 1,2,3,4,5,6  n=6 → lower middle K=3 → 3
      E : constant Element_Array := [6, 1, 4, 2, 5, 3];
   begin
      Expect_Median (E, "even n=6 lower middle");
      Expect_Kth (E, 3, "even k=3");
      Expect_Kth (E, 4, "even upper middle k=4");
      Expect_Kth (E, 1, "even min");
      Expect_Kth (E, 6, "even max");
   end;

   ---------------------------------------------------------------------
   Section ("4. Duplicates");
   ---------------------------------------------------------------------
   declare
      D  : constant Element_Array := [5, 1, 5, 2, 5, 3, 5];
      --  Sorted: 1,2,3,5,5,5,5
      Eq : constant Element_Array := [7, 7, 7, 7, 7];
   begin
      Expect_Kth (D, 1, "dup min");
      Expect_Kth (D, 7, "dup max");
      Expect_Kth (D, 4, "dup first 5");
      Expect_Kth (D, 5, "dup second 5");
      Expect_Median (D, "dup Median");
      Expect_Kth (Eq, 1, "all-equal min");
      Expect_Kth (Eq, 3, "all-equal mid");
      Expect_Kth (Eq, 5, "all-equal max");
      Expect_Median (Eq, "all-equal Median");
      Expect_Kth_Copy (D, 2, "dup copy");
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
      Expect_Kth (R, 10, "reverse max");
      Expect_Median (R, "reverse Median even");
      Expect_Kth (N, 4, "nearly k=4");
      Expect_Kth_Copy (R, 5, "reverse copy k=5");
   end;

   ---------------------------------------------------------------------
   Section ("6. Negatives, zero, mixed");
   ---------------------------------------------------------------------
   declare
      M : constant Element_Array := [-5, 0, 3, -2, 1, -8, 4];
      --  Sorted: -8,-5,-2,0,1,3,4
   begin
      Expect_Kth (M, 1, "mixed min");
      Expect_Kth (M, 4, "mixed median rank");
      Expect_Kth (M, 7, "mixed max");
      Expect_Median (M, "mixed Median");
      Expect_Kth ([0, 0, 0], 2, "zeros k=2");
      Expect_Kth ([-1, -3, -2], 2, "all neg mid");
   end;

   ---------------------------------------------------------------------
   Section ("7. Wikipedia-style examples");
   ---------------------------------------------------------------------
   --  Classic demo: find 3rd smallest of {9, 3, 2, 7, 1, 8, 5} → 3
   Expect_Kth ([9, 3, 2, 7, 1, 8, 5], 3, "wiki-ish 3rd");
   Expect_Kth ([9, 3, 2, 7, 1, 8, 5], 1, "wiki-ish min");
   Expect_Kth ([9, 3, 2, 7, 1, 8, 5], 7, "wiki-ish max");
   Expect_Median ([9, 3, 2, 7, 1, 8, 5], "wiki-ish Median");

   ---------------------------------------------------------------------
   Section ("8. Non-1 A'First bounds");
   ---------------------------------------------------------------------
   declare
      A : Element_Array (0 .. 4) := [10, 40, 30, 20, 50];
      B : constant Element_Array (5 .. 9) := [4, 1, 3, 2, 0];
      Got : Integer;
   begin
      Got := Select_Kth (A, 1);
      Check (Got = 10, "0-based min");
      Got := Select_Kth (A, 5);
      Check (Got = 50, "0-based max");
      Expect_Kth_Copy (B, 3, "5-based copy k=3");
      Expect_Median (B, "5-based Median");
   end;

   ---------------------------------------------------------------------
   Section ("9. Partition invariant after Select_Kth");
   ---------------------------------------------------------------------
   declare
      Src : constant Element_Array := [8, 1, 6, 3, 9, 2, 7, 4, 5];
      A   : Element_Array := Copy_Of (Src);
      K   : constant Positive := 4;
      Got : constant Integer := Select_Kth (A, K);
      Idx : constant Natural := A'First + (K - 1);
      Ok_Left, Ok_Right : Boolean := True;
   begin
      Check (Got = Reference_Kth (Src, K), "invariant value");
      Check (A (Idx) = Got, "result at rank index");
      for I in A'First .. Idx - 1 loop
         if A (I) > Got then
            Ok_Left := False;
         end if;
      end loop;
      for I in Idx + 1 .. A'Last loop
         if A (I) < Got then
            Ok_Right := False;
         end if;
      end loop;
      Check (Ok_Left, "left side ≤ k-th");
      Check (Ok_Right, "right side ≥ k-th");
   end;

   ---------------------------------------------------------------------
   Section ("10. Invalid_Argument");
   ---------------------------------------------------------------------
   declare
      Empty : Element_Array (1 .. 0);
      Tiny  : constant Element_Array := [1, 2, 3];
      Huge  : constant Element_Array (1 .. Max_N + 1) := [others => 0];
   begin
      Check (Select_Raises (Empty, 1), "empty Select_Kth");
      Check (Copy_Raises (Empty, 1), "empty Select_Kth_Copy");
      Check (Median_Raises (Empty), "empty Median");
      Check (Select_Raises (Tiny, 4), "K > n Select_Kth");
      Check (Copy_Raises (Tiny, 4), "K > n Select_Kth_Copy");
      Check (Select_Raises (Tiny, 100), "K >> n");
      Check (Select_Raises (Huge, 1), "n > Max_N Select_Kth");
      Check (Copy_Raises (Huge, 1), "n > Max_N Select_Kth_Copy");
      Check (Median_Raises (Huge), "n > Max_N Median");
   end;

   ---------------------------------------------------------------------
   Section ("11. Random vs sorted reference");
   ---------------------------------------------------------------------
   declare
      Lens : constant array (Positive range <>) of Positive :=
        [5, 10, 17, 32, 50, 100];
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
   Section ("12. Larger n vs reference");
   ---------------------------------------------------------------------
   declare
      A : constant Element_Array := Random_Array (500, -1000, 1000);
      Ks : constant array (Positive range <>) of Positive :=
        [1, 2, 50, 250, 251, 499, 500];
   begin
      for K of Ks loop
         Expect_Kth (A, K, "n=500 k=" & K'Image);
      end loop;
      Expect_Kth_Copy (A, 100, "n=500 copy k=100");
      Expect_Median (A, "n=500 Median");
   end;

   ---------------------------------------------------------------------
   Section ("13. All ranks on small permutation");
   ---------------------------------------------------------------------
   declare
      P : constant Element_Array := [4, 1, 3, 2, 0];
   begin
      for K in 1 .. 5 loop
         Expect_Kth (P, K, "perm k=" & K'Image);
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("14. Two-element and three-element exhaustive");
   ---------------------------------------------------------------------
   Expect_Kth ([1, 2], 1, "asc2 k1");
   Expect_Kth ([1, 2], 2, "asc2 k2");
   Expect_Kth ([2, 1], 1, "desc2 k1");
   Expect_Kth ([2, 1], 2, "desc2 k2");
   Expect_Kth ([3, 1, 2], 1, "perm3 k1");
   Expect_Kth ([3, 1, 2], 2, "perm3 k2");
   Expect_Kth ([3, 1, 2], 3, "perm3 k3");
   Expect_Median ([3, 1, 2], "perm3 Median");

   New_Line;
   Put_Line
     ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image & " FAIL");

   if Fail_Count > 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
