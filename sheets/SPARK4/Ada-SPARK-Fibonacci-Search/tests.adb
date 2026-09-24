--  Standalone test suite for Fibonacci_Search (SPARK port).
--  Preconditions replace exceptions; only valid call paths are exercised.
--  Sentinel is always 0 (indices are 1 .. N).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Fibonacci_Search; use Fibonacci_Search;

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

   --  Fibonacci Find and linear reference must agree on presence / absence
   --  (indices may differ when duplicates exist).
   procedure Expect_Agree
     (A : Element_Array; Key : Integer; Label : String)
   is
      F     : constant Index := Find (A, Key);
      C     : constant Index := Linear_Find (A, Key);
      F_Hit : constant Boolean := Is_Hit (A, Key, F);
      C_Hit : constant Boolean := Is_Hit (A, Key, C);
   begin
      Check (F_Hit = C_Hit, Label & " presence agrees");
      if not F_Hit then
         Check (Idx (F) = 0 and then Idx (C) = 0, Label & " both sentinel");
      end if;
   end Expect_Agree;

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
   Put_Line ("Fibonacci_Search (SPARK) tests");
   Put_Line ("==============================");

   ------------------------------------------------------------------
   Section ("1. Empty and singleton");
   ------------------------------------------------------------------
   declare
      Empty : Element_Array (1 .. 0);
      One   : constant Element_Array := [1 => 42];
   begin
      Check (In_Bounds (Empty), "empty In_Bounds");
      Check (Is_Sorted (Empty), "empty Is_Sorted");
      Check (Idx (Find (Empty, 0)) = 0, "empty Find sentinel");
      Check (Idx (Find (Empty, 99)) = 0, "empty any key sentinel");

      Check (Is_Sorted (One), "singleton Is_Sorted");
      Check (Idx (Find (One, 42)) = 1, "singleton hit");
      Expect_Miss (One, 41, "singleton miss low");
      Expect_Miss (One, 43, "singleton miss high");
   end;

   ------------------------------------------------------------------
   Section ("2. Wikipedia example (n = 11, key = 85)");
   ------------------------------------------------------------------
   declare
      Wiki : constant Element_Array (1 .. 11) :=
        [10, 22, 35, 40, 45, 50, 80, 82, 85, 90, 100];
   begin
      Check (Is_Sorted (Wiki), "wiki Is_Sorted");
      Expect_Hit (Wiki, 85, "wiki find 85");
      Check (Idx (Find (Wiki, 85)) = 9, "wiki 85 at index 9");
      Expect_Hit (Wiki, 10, "wiki first");
      Expect_Hit (Wiki, 100, "wiki last");
      Expect_Hit (Wiki, 50, "wiki mid 50");
      Expect_Hit (Wiki, 82, "wiki 82");
      Expect_Miss (Wiki, 0, "wiki miss below");
      Expect_Miss (Wiki, 83, "wiki miss between");
      Expect_Miss (Wiki, 101, "wiki miss above");
      Expect_Miss (Wiki, 42, "wiki miss 42");
   end;

   ------------------------------------------------------------------
   Section ("3. Small sorted arrays — hits and misses");
   ------------------------------------------------------------------
   declare
      A : constant Element_Array (1 .. 5) := [2, 4, 6, 8, 10];
      W : constant Element_Array (1 .. 10) :=
        [0, 1, 1, 2, 3, 5, 8, 13, 21, 34];
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

      Expect_Hit (W, 0, "fib-seq first");
      Expect_Hit (W, 34, "fib-seq last");
      Expect_Hit (W, 8, "fib-seq 8");
      Expect_Hit (W, 13, "fib-seq 13");
      Expect_Hit (W, 1, "fib-seq dup 1");
      Expect_Miss (W, -1, "fib-seq miss -1");
      Expect_Miss (W, 4, "fib-seq miss 4");
      Expect_Miss (W, 22, "fib-seq miss 22");
      Expect_Miss (W, 100, "fib-seq miss 100");
   end;

   ------------------------------------------------------------------
   Section ("4. Various lengths (incl. Fibonacci-sized n)");
   ------------------------------------------------------------------
   declare
      A2  : constant Element_Array := Make_Arithmetic (2, 10, 10);
      A3  : constant Element_Array := Make_Arithmetic (3, 1, 1);
      A5  : constant Element_Array := Make_Arithmetic (5, 0, 2);
      A8  : constant Element_Array := Make_Arithmetic (8, 1, 1);
      A13 : constant Element_Array := Make_Arithmetic (13, 1, 1);
      A21 : constant Element_Array := Make_Arithmetic (21, 0, 1);
      A7  : constant Element_Array := Make_Arithmetic (7, 100, 1);
      A10 : constant Element_Array := Make_Arithmetic (10, 1, 3);
      A15 : constant Element_Array := Make_Arithmetic (15, 0, 1);
      A17 : constant Element_Array := Make_Arithmetic (17, 5, 5);
      A34 : constant Element_Array := Make_Arithmetic (34, 1, 1);
      A55 : constant Element_Array := Make_Arithmetic (55, 1, 1);
   begin
      Expect_Hit (A2, 10, "n=2 first");
      Expect_Hit (A2, 20, "n=2 last");
      Expect_Miss (A2, 15, "n=2 miss");

      Expect_Hit (A3, 1, "n=3 first");
      Expect_Hit (A3, 2, "n=3 mid");
      Expect_Hit (A3, 3, "n=3 last");
      Expect_Miss (A3, 0, "n=3 miss");

      Expect_Hit (A5, 0, "n=5 first");
      Expect_Hit (A5, 8, "n=5 last");
      Expect_Hit (A5, 4, "n=5 mid");
      Expect_Miss (A5, 1, "n=5 miss odd");

      Expect_Hit (A8, 1, "n=8 first (F_6)");
      Expect_Hit (A8, 8, "n=8 last");
      Expect_Hit (A8, 5, "n=8 mid");
      Expect_Miss (A8, 9, "n=8 miss");

      Expect_Hit (A13, 1, "n=13 first (F_7)");
      Expect_Hit (A13, 13, "n=13 last");
      Expect_Hit (A13, 7, "n=13 mid");
      Expect_Miss (A13, 0, "n=13 miss");

      Expect_Hit (A21, 0, "n=21 first (F_8)");
      Expect_Hit (A21, 20, "n=21 last");
      Expect_Hit (A21, 10, "n=21 mid");
      Expect_Miss (A21, 21, "n=21 miss");

      Expect_Hit (A7, 100, "n=7 first");
      Expect_Hit (A7, 106, "n=7 last");
      Expect_Hit (A7, 103, "n=7 mid");
      Expect_Miss (A7, 99, "n=7 miss low");
      Expect_Miss (A7, 107, "n=7 miss high");

      Expect_Hit (A10, 1, "n=10 first");
      Expect_Hit (A10, 28, "n=10 last");
      Expect_Hit (A10, 16, "n=10 mid");
      Expect_Miss (A10, 2, "n=10 miss");

      Expect_Hit (A15, 0, "n=15 first");
      Expect_Hit (A15, 14, "n=15 last");
      Expect_Hit (A15, 7, "n=15 mid");
      Expect_Miss (A15, 15, "n=15 miss");

      Expect_Hit (A17, 5, "n=17 first");
      Expect_Hit (A17, 85, "n=17 last");
      Expect_Hit (A17, 45, "n=17 mid");
      Expect_Miss (A17, 0, "n=17 miss low");
      Expect_Miss (A17, 90, "n=17 miss high");

      Expect_Hit (A34, 1, "n=34 first (F_9)");
      Expect_Hit (A34, 34, "n=34 last");
      Expect_Hit (A34, 17, "n=34 mid");
      Expect_Miss (A34, 0, "n=34 miss");

      Expect_Hit (A55, 1, "n=55 first (F_10)");
      Expect_Hit (A55, 55, "n=55 last");
      Expect_Hit (A55, 28, "n=55 mid");
      Expect_Miss (A55, 56, "n=55 miss");
   end;

   ------------------------------------------------------------------
   Section ("5. Vs linear reference");
   ------------------------------------------------------------------
   declare
      A : constant Element_Array (1 .. 20) :=
        Make_Arithmetic (20, 1, 1);
      B : constant Element_Array (1 .. 12) :=
        [10, 22, 35, 40, 45, 50, 80, 82, 85, 90, 100, 200];
      C : constant Element_Array := Make_Arithmetic (50, 0, 2);
   begin
      for K in 1 .. 20 loop
         Expect_Agree (A, K, "lin-ref A hit" & Integer'Image (K));
      end loop;
      Expect_Agree (A, 0, "lin-ref A miss 0");
      Expect_Agree (A, 21, "lin-ref A miss 21");

      Expect_Agree (B, 85, "lin-ref B 85");
      Expect_Agree (B, 10, "lin-ref B first");
      Expect_Agree (B, 200, "lin-ref B last");
      Expect_Agree (B, 83, "lin-ref B miss 83");
      Expect_Agree (B, 0, "lin-ref B miss 0");

      Expect_Agree (C, 0, "lin-ref C first");
      Expect_Agree (C, 98, "lin-ref C last");
      Expect_Agree (C, 50, "lin-ref C mid");
      Expect_Agree (C, 1, "lin-ref C miss odd");
      Expect_Agree (C, -2, "lin-ref C miss low");
      Expect_Agree (C, 100, "lin-ref C miss high");
   end;

   ------------------------------------------------------------------
   Section ("6. Duplicates");
   ------------------------------------------------------------------
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
      Expect_Agree (D1, 2, "dup mid vs linear");

      Got := Find (D2, 3);
      Check (Is_Hit (D2, 3, Got), "all-equal hit");
      Expect_Miss (D2, 2, "all-equal miss low");
      Expect_Miss (D2, 4, "all-equal miss high");

      Expect_Hit (D3, 1, "paired dup 1");
      Expect_Hit (D3, 4, "paired dup 4");
      Expect_Hit (D3, 9, "paired dup 9");
      Expect_Miss (D3, 5, "paired dup miss 5");
   end;

   ------------------------------------------------------------------
   Section ("7. Negatives and mixed signs");
   ------------------------------------------------------------------
   declare
      Neg : constant Element_Array (1 .. 7) :=
        [-50, -20, -10, 0, 10, 20, 50];
   begin
      Expect_Hit (Neg, -50, "neg first");
      Expect_Hit (Neg, -10, "neg -10");
      Expect_Hit (Neg, 0, "neg zero");
      Expect_Hit (Neg, 50, "neg last");
      Expect_Miss (Neg, -60, "neg miss below");
      Expect_Miss (Neg, -15, "neg miss between");
      Expect_Miss (Neg, 5, "neg miss 5");
      Expect_Miss (Neg, 60, "neg miss above");
      Expect_Agree (Neg, -20, "neg vs linear -20");
      Expect_Agree (Neg, 15, "neg vs linear miss 15");
   end;

   ------------------------------------------------------------------
   Section ("8. Two- and three-element edge cases");
   ------------------------------------------------------------------
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

   ------------------------------------------------------------------
   Section ("9. Max_N vs linear reference");
   ------------------------------------------------------------------
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

      Expect_Hit (A, 1, "n=64 first");
      Expect_Hit (A, 64, "n=64 last");
      Expect_Hit (A, 32, "n=64 mid");
      Expect_Miss (A, 0, "n=64 miss 0");
      Expect_Miss (A, 65, "n=64 miss 65");
   end;

   ------------------------------------------------------------------
   Section ("10. Duplicates at Max_N scale vs linear");
   ------------------------------------------------------------------
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

   ------------------------------------------------------------------
   Section ("11. Random queries on sorted random array");
   ------------------------------------------------------------------
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

      for Trial in 1 .. 15 loop
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

   ------------------------------------------------------------------
   Section ("12. Boundary keys and Is_Sorted / In_Bounds");
   ------------------------------------------------------------------
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
      Expect_Hit (A, 400, "endpoint mid");
      Expect_Miss (A, 450, "between mid");
      Expect_Agree (A, 600, "endpoint vs linear 600");
      Expect_Agree (A, 550, "endpoint vs linear miss 550");

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

   New_Line;
   Put_Line ("Results: "
             & Natural'Image (Pass_Count) & " PASS,"
             & Natural'Image (Fail_Count) & " FAIL");
   if Fail_Count /= 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
