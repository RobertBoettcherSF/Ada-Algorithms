--  Standalone test suite for Fibonacci_Search (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Fibonacci_Search; use Fibonacci_Search;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check
     (Condition : Boolean;
      Message   : String)
   is
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
   function I (X : Integer) return Integer is (X);

   function Sentinel (A : Element_Array) return Integer is
     (Integer (A'First) - 1);

   function Is_Hit
     (A   : Element_Array;
      Key : Integer;
      Got : Integer) return Boolean
   is
   begin
      return Got >= Integer (A'First)
        and then Got <= Integer (A'Last)
        and then A (Natural (Got)) = Key;
   end Is_Hit;

   -------------------------------------------------------------------------
   -- Classic binary search (local reference oracle — not part of the API)
   -------------------------------------------------------------------------

   function Classic_Binary_Search
     (A   : Element_Array;
      Key : Integer) return Integer
   is
      Lo  : Integer;
      Hi  : Integer;
      Mid : Integer;
   begin
      if A'Length = 0 then
         return Integer (A'First) - 1;
      end if;

      Lo := Integer (A'First);
      Hi := Integer (A'Last);

      while Lo <= Hi loop
         Mid := Lo + (Hi - Lo) / 2;
         if A (Natural (Mid)) = Key then
            return Mid;
         elsif A (Natural (Mid)) < Key then
            Lo := Mid + 1;
         else
            Hi := Mid - 1;
         end if;
      end loop;

      return Integer (A'First) - 1;
   end Classic_Binary_Search;

   procedure Expect_Hit
     (A     : Element_Array;
      Key   : Integer;
      Label : String)
   is
      Got : constant Integer := Find (A, Key);
   begin
      Check (Is_Hit (A, Key, Got), Label);
   end Expect_Hit;

   procedure Expect_Miss
     (A     : Element_Array;
      Key   : Integer;
      Label : String)
   is
   begin
      Check (Find (A, Key) = Sentinel (A), Label);
   end Expect_Miss;

   --  Fibonacci Find and classic binary must agree on presence / absence
   --  (indices may differ when duplicates exist).
   procedure Expect_Agree
     (A     : Element_Array;
      Key   : Integer;
      Label : String)
   is
      F : constant Integer := Find (A, Key);
      C : constant Integer := Classic_Binary_Search (A, Key);
      F_Hit : constant Boolean := Is_Hit (A, Key, F);
      C_Hit : constant Boolean := Is_Hit (A, Key, C);
   begin
      Check (F_Hit = C_Hit, Label & " presence agrees");
      if not F_Hit then
         Check (F = Sentinel (A) and then C = Sentinel (A),
                Label & " both sentinel");
      end if;
   end Expect_Agree;

   function Find_Raises (A : Element_Array; Key : Integer) return Boolean is
      Unused : Integer;
   begin
      Unused := Find (A, Key);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Find_Raises;

   --  Uniform arithmetic sequence A(First + k) = First_Val + k * Step_Val.
   function Make_Arithmetic
     (First_Index : Natural;
      Len         : Positive;
      First_Val   : Integer;
      Step_Val    : Positive) return Element_Array
   is
      A : Element_Array (First_Index .. First_Index + Len - 1);
   begin
      for K in 0 .. Len - 1 loop
         A (First_Index + K) := First_Val + K * Step_Val;
      end loop;
      return A;
   end Make_Arithmetic;

begin
   Put_Line ("Fibonacci_Search tests");
   Put_Line ("======================");

   ------------------------------------------------------------------
   Section ("1. Empty and singleton");
   ------------------------------------------------------------------
   declare
      E1 : Element_Array (1 .. 0);
      E5 : Element_Array (5 .. 4);
      S0 : constant Element_Array (0 .. 0) := [42];
      S1 : constant Element_Array (1 .. 1) := [7];
      S5 : constant Element_Array (5 .. 5) := [-3];
   begin
      Expect_Miss (E1, 0, "empty 1..0 miss");
      Expect_Miss (E1, 99, "empty 1..0 any key");
      Expect_Miss (E5, 1, "empty 5..4 miss");
      Check (Find (E1, I (5)) = 0, "empty 1..0 sentinel 0");
      Check (Find (E5, I (5)) = 4, "empty 5..4 sentinel 4");

      Expect_Hit (S0, 42, "singleton 0-based hit");
      Expect_Miss (S0, 41, "singleton 0-based miss low");
      Expect_Miss (S0, 43, "singleton 0-based miss high");
      Expect_Hit (S1, 7, "singleton 1-based hit");
      Expect_Miss (S1, 0, "singleton 1-based miss");
      Expect_Hit (S5, -3, "singleton high-index hit");
      Expect_Miss (S5, 0, "singleton high-index miss");
   end;

   ------------------------------------------------------------------
   Section ("2. Wikipedia example (n = 11, key = 85)");
   ------------------------------------------------------------------
   declare
      Wiki : constant Element_Array (0 .. 10) :=
        [10, 22, 35, 40, 45, 50, 80, 82, 85, 90, 100];
   begin
      Expect_Hit (Wiki, 85, "wiki find 85");
      Check (Find (Wiki, 85) = 8, "wiki 85 at index 8");
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
   begin
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
   end;

   declare
      W : constant Element_Array (0 .. 9) :=
        [0, 1, 1, 2, 3, 5, 8, 13, 21, 34];
   begin
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
      --  Lengths near Fibonacci numbers and arbitrary sizes.
      A2  : constant Element_Array := Make_Arithmetic (1, 2, 10, 10);
      A3  : constant Element_Array := Make_Arithmetic (1, 3, 1, 1);
      A5  : constant Element_Array := Make_Arithmetic (0, 5, 0, 2);
      A8  : constant Element_Array := Make_Arithmetic (1, 8, 1, 1);
      A13 : constant Element_Array := Make_Arithmetic (1, 13, 1, 1);
      A21 : constant Element_Array := Make_Arithmetic (0, 21, 0, 1);
      A7  : constant Element_Array := Make_Arithmetic (1, 7, 100, 1);
      A10 : constant Element_Array := Make_Arithmetic (1, 10, 1, 3);
      A15 : constant Element_Array := Make_Arithmetic (1, 15, 0, 1);
      A17 : constant Element_Array := Make_Arithmetic (0, 17, 5, 5);
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
   end;

   ------------------------------------------------------------------
   Section ("5. Vs classic binary search reference");
   ------------------------------------------------------------------
   declare
      A : constant Element_Array (1 .. 20) :=
        Make_Arithmetic (1, 20, 1, 1);
      B : constant Element_Array (0 .. 11) :=
        [10, 22, 35, 40, 45, 50, 80, 82, 85, 90, 100, 200];
      C : constant Element_Array := Make_Arithmetic (1, 50, 0, 2);
   begin
      for K in 1 .. 20 loop
         Expect_Agree (A, K, "bin-ref A hit" & Integer'Image (K));
      end loop;
      Expect_Agree (A, 0, "bin-ref A miss 0");
      Expect_Agree (A, 21, "bin-ref A miss 21");

      Expect_Agree (B, 85, "bin-ref B 85");
      Expect_Agree (B, 10, "bin-ref B first");
      Expect_Agree (B, 200, "bin-ref B last");
      Expect_Agree (B, 83, "bin-ref B miss 83");
      Expect_Agree (B, 0, "bin-ref B miss 0");

      Expect_Agree (C, 0, "bin-ref C first");
      Expect_Agree (C, 98, "bin-ref C last");
      Expect_Agree (C, 50, "bin-ref C mid");
      Expect_Agree (C, 1, "bin-ref C miss odd");
      Expect_Agree (C, -2, "bin-ref C miss low");
      Expect_Agree (C, 100, "bin-ref C miss high");
   end;

   ------------------------------------------------------------------
   Section ("6. Duplicates");
   ------------------------------------------------------------------
   declare
      D1  : constant Element_Array (1 .. 5) := [1, 2, 2, 2, 5];
      D2  : constant Element_Array (0 .. 6) := [3, 3, 3, 3, 3, 3, 3];
      D3  : constant Element_Array (1 .. 6) := [1, 1, 4, 4, 9, 9];
      Got : Integer;
   begin
      Got := Find (D1, 2);
      Check (Is_Hit (D1, 2, Got), "dup mid run hit");
      Expect_Hit (D1, 1, "dup first unique");
      Expect_Hit (D1, 5, "dup last unique");
      Expect_Miss (D1, 3, "dup miss 3");
      Expect_Agree (D1, 2, "dup mid vs binary");

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
      Expect_Agree (Neg, -20, "neg vs binary -20");
      Expect_Agree (Neg, 15, "neg vs binary miss 15");
   end;

   ------------------------------------------------------------------
   Section ("8. Index bases (0-based vs 1-based vs offset)");
   ------------------------------------------------------------------
   declare
      A0 : constant Element_Array (0 .. 3) := [10, 20, 30, 40];
      A1 : constant Element_Array (1 .. 4) := [10, 20, 30, 40];
      A9 : constant Element_Array (9 .. 12) := [10, 20, 30, 40];
   begin
      Check (Find (A0, 10) = 0, "0-based index of 10");
      Check (Find (A0, 40) = 3, "0-based index of 40");
      Check (Find (A1, 10) = 1, "1-based index of 10");
      Check (Find (A1, 40) = 4, "1-based index of 40");
      Check (Find (A9, 10) = 9, "offset index of 10");
      Check (Find (A9, 30) = 11, "offset index of 30");
      Expect_Miss (A9, 25, "offset miss");
   end;

   ------------------------------------------------------------------
   Section ("9. Larger arrays");
   ------------------------------------------------------------------
   declare
      Len50  : constant := 50;
      Len100 : constant := 100;
      Len101 : constant := 101;
      Len250 : constant := 250;
      A50    : constant Element_Array :=
        Make_Arithmetic (1, Len50, 1, 1);
      A100   : constant Element_Array :=
        Make_Arithmetic (1, Len100, 1, 1);
      A101   : constant Element_Array :=
        Make_Arithmetic (0, Len101, 0, 1);
      A250   : constant Element_Array :=
        Make_Arithmetic (1, Len250, 1, 2);
   begin
      Expect_Hit (A50, 1, "n=50 first");
      Expect_Hit (A50, 50, "n=50 last");
      Expect_Hit (A50, 25, "n=50 mid");
      Expect_Miss (A50, 0, "n=50 miss 0");
      Expect_Miss (A50, 51, "n=50 miss 51");
      Expect_Agree (A50, 37, "n=50 vs binary 37");

      Expect_Hit (A100, 1, "n=100 first");
      Expect_Hit (A100, 100, "n=100 last");
      Expect_Hit (A100, 37, "n=100 37");
      Expect_Miss (A100, 101, "n=100 miss");
      Expect_Agree (A100, 64, "n=100 vs binary 64");

      Expect_Hit (A101, 0, "n=101 first");
      Expect_Hit (A101, 100, "n=101 last");
      Expect_Hit (A101, 50, "n=101 mid");
      Expect_Miss (A101, 101, "n=101 miss");

      Expect_Hit (A250, 1, "n=250 first");
      Expect_Hit (A250, 499, "n=250 last");
      Expect_Hit (A250, 251, "n=250 mid odd");
      Expect_Miss (A250, 2, "n=250 miss even");
      Expect_Miss (A250, 500, "n=250 miss high");
      Expect_Agree (A250, 251, "n=250 vs binary");
   end;

   ------------------------------------------------------------------
   Section ("10. Two- and three-element edge cases");
   ------------------------------------------------------------------
   declare
      T2 : constant Element_Array (1 .. 2) := [5, 9];
      T3 : constant Element_Array (0 .. 2) := [1, 2, 3];
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
   Section ("11. Invalid_Argument — Max_N");
   ------------------------------------------------------------------
   Check (I (Integer (Max_N)) = 100_000, "Max_N is 100_000");
   Check (not Find_Raises (Make_Arithmetic (1, 3, 1, 1), 2),
          "small array does not raise");

   declare
      type Acc is access Element_Array;
      Big : constant Acc := new Element_Array'(1 .. Max_N + 1 => 0);
      Ok  : constant Acc := new Element_Array'(1 .. Max_N => 0);
   begin
      Check (Find_Raises (Big.all, 0),
             "length Max_N+1 raises Invalid_Argument");
      Check (not Find_Raises (Ok.all, 0), "length Max_N accepted");
      Expect_Hit (Ok.all, 0, "Max_N all-zero hit");
      Expect_Miss (Ok.all, 1, "Max_N all-zero miss");
   end;

   ------------------------------------------------------------------
   Section ("12. Boundary keys equal to endpoints");
   ------------------------------------------------------------------
   declare
      A : constant Element_Array (1 .. 8) :=
        [100, 200, 300, 400, 500, 600, 700, 800];
   begin
      Expect_Hit (A, 100, "endpoint low");
      Expect_Hit (A, 800, "endpoint high");
      Expect_Miss (A, 99, "just below low");
      Expect_Miss (A, 801, "just above high");
      Expect_Hit (A, 400, "endpoint mid");
      Expect_Miss (A, 450, "between mid");
      Expect_Agree (A, 600, "endpoint vs binary 600");
      Expect_Agree (A, 550, "endpoint vs binary miss 550");
   end;

   New_Line;
   Put_Line ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image
             & " FAIL");

   if Fail_Count /= 0 then
      raise Program_Error with "test failures present";
   end if;
end Tests;
