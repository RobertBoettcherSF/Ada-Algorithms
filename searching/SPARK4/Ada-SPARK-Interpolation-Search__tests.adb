--  Standalone test suite for Interpolation_Search (SPARK port).
--  Preconditions replace exceptions; only valid call paths are exercised.
--  Sentinel is always 0 (indices are 1 .. N).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Interpolation_Search; use Interpolation_Search;

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
   function Idx (X : Index) return Index is (X);
   function Nat (X : Natural) return Natural is (X);
   function Int (X : Integer) return Integer is (X);

   function Linear_Find (A : Element_Array; Key : Integer) return Index is
   begin
      for I in A'Range loop
         if A (I) = Key then
            return I;
         end if;
      end loop;
      return 0;
   end Linear_Find;

   function Is_Hit
     (A : Element_Array; Key : Integer; Got : Index) return Boolean
   is
   begin
      return Got >= 1 and then Got <= A'Last and then A (Got) = Key;
   end Is_Hit;

   procedure Expect_Hit
     (A : Element_Array; Key : Integer; Label : String)
   is
      Got : constant Index := Find (A, Key);
   begin
      Check (Is_Hit (A, Key, Got), Label);
   end Expect_Hit;

   procedure Expect_Miss
     (A : Element_Array; Key : Integer; Label : String)
   is
   begin
      Check (Idx (Find (A, Key)) = 0, Label);
   end Expect_Miss;

   function Make_Arithmetic
     (Len       : Positive;
      First_Val : Integer;
      Step_Val  : Positive) return Element_Array
   is
      A : Element_Array (1 .. Len);
   begin
      for K in 0 .. Len - 1 loop
         A (1 + K) := First_Val + K * Step_Val;
      end loop;
      return A;
   end Make_Arithmetic;

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

begin
   Put_Line ("Interpolation_Search (SPARK) tests");
   Put_Line ("==================================");

   Section ("1. Empty and singleton");
   declare
      Empty : Element_Array (1 .. 0);
      One   : constant Element_Array := [1 => 42];
      Neg   : constant Element_Array := [1 => -3];
   begin
      Check (In_Bounds (Empty), "empty In_Bounds");
      Check (Is_Sorted (Empty), "empty Is_Sorted");
      Check (Idx (Find (Empty, 0)) = 0, "empty Find sentinel");
      Check (Idx (Find (Empty, 99)) = 0, "empty any key");

      Check (Is_Sorted (One), "singleton Is_Sorted");
      Check (Idx (Find (One, 42)) = 1, "singleton hit");
      Expect_Miss (One, 41, "singleton miss low");
      Expect_Miss (One, 43, "singleton miss high");
      Expect_Hit (Neg, -3, "singleton neg hit");
      Expect_Miss (Neg, 0, "singleton neg miss");
   end;

   Section ("2. Uniform arithmetic sequence (best case)");
   declare
      A : constant Element_Array := Make_Arithmetic (20, 10, 10);
      --  10,20,...,200
      Z : constant Element_Array := Make_Arithmetic (16, 0, 1);
      --  0..15
   begin
      Expect_Hit (A, 10, "arith first");
      Expect_Hit (A, 200, "arith last");
      Expect_Hit (A, 100, "arith middle 100");
      Expect_Hit (A, 50, "arith 50");
      Expect_Hit (A, 150, "arith 150");
      Expect_Miss (A, 0, "arith miss below");
      Expect_Miss (A, 210, "arith miss above");
      Expect_Miss (A, 15, "arith miss between");
      Expect_Miss (A, 105, "arith miss between 105");

      for K in 0 .. 15 loop
         Expect_Hit (Z, K, "dense hit" & Integer'Image (K));
      end loop;
      Expect_Miss (Z, -1, "dense miss -1");
      Expect_Miss (Z, 16, "dense miss 16");
   end;

   Section ("3. Small sorted arrays — hits and misses");
   declare
      A : constant Element_Array (1 .. 5) := [2, 4, 6, 8, 10];
      W : constant Element_Array (1 .. 10) :=
        [1, 3, 5, 6, 7, 9, 14, 15, 17, 19];
   begin
      Check (Is_Sorted (A), "small Is_Sorted");
      Expect_Hit (A, 2, "small first");
      Expect_Hit (A, 4, "small second");
      Expect_Hit (A, 6, "small mid");
      Expect_Hit (A, 8, "small fourth");
      Expect_Hit (A, 10, "small last");
      Expect_Miss (A, 1, "small miss below");
      Expect_Miss (A, 3, "small miss between 3");
      Expect_Miss (A, 5, "small miss between 5");
      Expect_Miss (A, 7, "small miss between 7");
      Expect_Miss (A, 9, "small miss between 9");
      Expect_Miss (A, 11, "small miss above");

      Expect_Hit (W, 1, "wiki-like first");
      Expect_Hit (W, 19, "wiki-like last");
      Expect_Hit (W, 7, "wiki-like 7");
      Expect_Hit (W, 14, "wiki-like 14");
      Expect_Miss (W, 0, "wiki-like miss 0");
      Expect_Miss (W, 8, "wiki-like miss 8");
      Expect_Miss (W, 20, "wiki-like miss 20");
      Expect_Miss (W, 12, "wiki-like miss 12");
   end;

   Section ("4. Duplicates");
   declare
      D1  : constant Element_Array (1 .. 5) := [1, 2, 2, 2, 5];
      D2  : constant Element_Array (1 .. 7) := [3, 3, 3, 3, 3, 3, 3];
      D3  : constant Element_Array (1 .. 6) := [1, 1, 4, 4, 9, 9];
      Got : Index;
   begin
      Got := Find (D1, 2);
      Check (Is_Hit (D1, 2, Got), "dup mid run hit");
      Expect_Hit (D1, 1, "dup first unique");
      Expect_Hit (D1, 5, "dup last unique");
      Expect_Miss (D1, 3, "dup miss 3");
      Expect_Miss (D1, 0, "dup miss 0");

      Got := Find (D2, 3);
      Check (Is_Hit (D2, 3, Got), "all-equal hit");
      Expect_Miss (D2, 2, "all-equal miss low");
      Expect_Miss (D2, 4, "all-equal miss high");

      Expect_Hit (D3, 1, "paired dup 1");
      Expect_Hit (D3, 4, "paired dup 4");
      Expect_Hit (D3, 9, "paired dup 9");
      Expect_Miss (D3, 5, "paired dup miss 5");
   end;

   Section ("5. Clustered / non-uniform values");
   declare
      C : constant Element_Array (1 .. 10) :=
        [1, 1, 1, 1, 2, 2, 2, 100, 1000, 10_000];
      E : constant Element_Array (1 .. 8) :=
        [1, 2, 4, 8, 16, 32, 64, 128];
   begin
      Expect_Hit (C, 1, "cluster hit 1");
      Expect_Hit (C, 2, "cluster hit 2");
      Expect_Hit (C, 100, "cluster hit 100");
      Expect_Hit (C, 1000, "cluster hit 1000");
      Expect_Hit (C, 10_000, "cluster hit 10000");
      Expect_Miss (C, 3, "cluster miss 3");
      Expect_Miss (C, 50, "cluster miss 50");
      Expect_Miss (C, 500, "cluster miss 500");
      Expect_Miss (C, 0, "cluster miss 0");
      Expect_Miss (C, 20_000, "cluster miss high");

      Expect_Hit (E, 1, "exp hit 1");
      Expect_Hit (E, 8, "exp hit 8");
      Expect_Hit (E, 64, "exp hit 64");
      Expect_Hit (E, 128, "exp hit 128");
      Expect_Miss (E, 3, "exp miss 3");
      Expect_Miss (E, 90, "exp miss 90");
      Expect_Miss (E, 256, "exp miss 256");
   end;

   Section ("6. Negatives and mixed signs");
   declare
      N : constant Element_Array (1 .. 7) :=
        [-50, -20, -10, 0, 10, 20, 50];
   begin
      Expect_Hit (N, -50, "neg first");
      Expect_Hit (N, -10, "neg -10");
      Expect_Hit (N, 0, "neg zero");
      Expect_Hit (N, 50, "neg last");
      Expect_Miss (N, -60, "neg miss below");
      Expect_Miss (N, -15, "neg miss between");
      Expect_Miss (N, 5, "neg miss 5");
      Expect_Miss (N, 60, "neg miss above");
   end;

   Section ("7. Two- and three-element edge cases");
   declare
      T2 : constant Element_Array (1 .. 2) := [5, 9];
      T3 : constant Element_Array (1 .. 3) := [1, 2, 3];
      Eq : constant Element_Array (1 .. 2) := [7, 7];
   begin
      Expect_Hit (T2, 5, "pair left");
      Expect_Hit (T2, 9, "pair right");
      Expect_Miss (T2, 6, "pair miss mid");
      Expect_Miss (T2, 4, "pair miss low");
      Expect_Miss (T2, 10, "pair miss high");

      Expect_Hit (T3, 1, "triple first");
      Expect_Hit (T3, 2, "triple mid");
      Expect_Hit (T3, 3, "triple last");
      Expect_Miss (T3, 0, "triple miss");

      Expect_Hit (Eq, 7, "equal pair hit");
      Expect_Miss (Eq, 6, "equal pair miss");
   end;

   Section ("8. Capacity-bound uniform array");
   declare
      A : constant Element_Array := Make_Arithmetic (Max_N, 1, 1);
   begin
      Expect_Hit (A, 1, "cap first");
      Expect_Hit (A, Max_N, "cap last");
      Expect_Hit (A, Max_N / 2, "cap mid");
      Expect_Hit (A, 17, "cap 17");
      Expect_Hit (A, Max_N - 1, "cap near last");
      Expect_Miss (A, 0, "cap miss 0");
      Expect_Miss (A, Max_N + 1, "cap miss above");
      Expect_Miss (A, -5, "cap miss neg");
   end;

   Section ("9. Max_N vs linear reference");
   declare
      N    : constant := Max_N;
      A    : Element_Array (1 .. N);
      Keys : constant Element_Array :=
        [1, 2, N / 2, N - 1, N, -1, N + 1, 42, 17, 33];
   begin
      for I in A'Range loop
         A (I) := I;
      end loop;
      Check (In_Bounds (A), "Max_N In_Bounds");
      Check (Is_Sorted (A), "Max_N Is_Sorted");

      for K of Keys loop
         declare
            Got : constant Index := Find (A, K);
            Ref : constant Index := Linear_Find (A, K);
         begin
            Check (Got = Ref,
                   "Max_N Find matches linear key=" & Integer'Image (K));
         end;
      end loop;
   end;

   Section ("10. Duplicates at Max_N scale vs linear");
   declare
      N : constant := Max_N;
      A : Element_Array (1 .. N);
   begin
      for I in A'Range loop
         A (I) := ((I - 1) / 4) + 1;
      end loop;

      for V in 1 .. 5 loop
         declare
            Got : constant Index := Find (A, V);
            Ref : constant Index := Linear_Find (A, V);
         begin
            Check (Got >= 1 and then A (Got) = V and then Ref >= 1,
                   "dup Find hit V=" & Integer'Image (V));
         end;
      end loop;
      Expect_Miss (A, 0, "dup miss 0");
      Expect_Miss (A, 10_000, "dup miss high");
   end;

   Section ("11. Random queries on sorted random array");
   declare
      N : constant := Max_N;
      A : Element_Array (1 .. N);
   begin
      Seed := 99;
      for I in A'Range loop
         A (I) := Integer (Next_Mod (1_000));
      end loop;
      for I in A'First + 1 .. A'Last loop
         declare
            Key : constant Integer := A (I);
            J   : Integer := I - 1;
         begin
            while J >= Integer (A'First) and then A (J) > Key loop
               A (J + 1) := A (J);
               J := J - 1;
            end loop;
            A (J + 1) := Key;
         end;
      end loop;
      Check (Is_Sorted (A), "random Is_Sorted");

      for Trial in 1 .. 20 loop
         declare
            K   : constant Integer := Integer (Next_Mod (1_000));
            Got : constant Index := Find (A, K);
            Ref : constant Index := Linear_Find (A, K);
         begin
            if Ref = 0 then
               Check (Idx (Got) = 0,
                      "rand miss trial" & Integer'Image (Trial));
            else
               Check (Is_Hit (A, K, Got),
                      "rand hit trial" & Integer'Image (Trial));
            end if;
         end;
      end loop;
   end;

   Section ("12. Boundary keys and Is_Sorted / In_Bounds");
   declare
      A    : constant Element_Array (1 .. 8) :=
        [100, 200, 300, 400, 500, 600, 700, 800];
      Good : constant Element_Array (1 .. 4) := [1, 2, 2, 9];
      Bad  : constant Element_Array (1 .. 4) := [1, 3, 2, 4];
      Cap  : Element_Array (1 .. Max_N);
   begin
      Expect_Hit (A, 100, "endpoint low");
      Expect_Hit (A, 800, "endpoint high");
      Expect_Miss (A, 99, "just below low");
      Expect_Miss (A, 801, "just above high");

      Check (Is_Sorted (Good), "Good Is_Sorted");
      Check (not Is_Sorted (Bad), "Bad not Is_Sorted");
      Check (In_Bounds (Good), "Good In_Bounds");
      for I in Cap'Range loop
         Cap (I) := I;
      end loop;
      Check (In_Bounds (Cap), "Cap In_Bounds at Max_N");
      Check (Nat (Max_N) = 64, "Max_N = 64");
      Check (Int (Find (Good, 2)) in 2 .. 3, "Good Find plateau");
   end;

   Section ("13. Wide value span (overflow-stress probe)");
   declare
      W : constant Element_Array (1 .. 5) :=
        [Integer'First / 2, -1000, 0, 1000, Integer'Last / 2];
   begin
      Expect_Hit (W, Integer'First / 2, "wide first");
      Expect_Hit (W, 0, "wide zero");
      Expect_Hit (W, Integer'Last / 2, "wide last");
      Expect_Hit (W, -1000, "wide -1000");
      Expect_Miss (W, 1, "wide miss 1");
      Expect_Miss (W, Integer'Last, "wide miss Last");
   end;

   New_Line;
   Put_Line ("Results: "
             & Natural'Image (Pass_Count) & " PASS,"
             & Natural'Image (Fail_Count) & " FAIL");
   if Fail_Count /= 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
