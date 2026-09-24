--  Standalone test suite for Jump_Search (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Jump_Search; use Jump_Search;

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
   function N (X : Natural) return Natural is (X);

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

   procedure Expect_Hit_Step
     (A     : Element_Array;
      Key   : Integer;
      Step  : Natural;
      Label : String)
   is
      Got : constant Integer := Find (A, Key, Step);
   begin
      Check (Is_Hit (A, Key, Got), Label);
   end Expect_Hit_Step;

   procedure Expect_Miss_Step
     (A     : Element_Array;
      Key   : Integer;
      Step  : Natural;
      Label : String)
   is
   begin
      Check (Find (A, Key, Step) = Sentinel (A), Label);
   end Expect_Miss_Step;

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

   function Find_Step_Raises
     (A    : Element_Array;
      Key  : Integer;
      Step : Natural) return Boolean
   is
      Unused : Integer;
   begin
      Unused := Find (A, Key, Step);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Find_Step_Raises;

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
   Put_Line ("Jump_Search tests");
   Put_Line ("=================");

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
   Section ("2. Small sorted arrays — hits and misses");
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
      --  Classic demo values (not a perfect-square length).
      W : constant Element_Array (0 .. 9) :=
        [0, 1, 1, 2, 3, 5, 8, 13, 21, 34];
   begin
      Expect_Hit (W, 0, "fib-like first");
      Expect_Hit (W, 34, "fib-like last");
      Expect_Hit (W, 8, "fib-like 8");
      Expect_Hit (W, 13, "fib-like 13");
      Expect_Hit (W, 1, "fib-like dup 1");
      Expect_Miss (W, -1, "fib-like miss -1");
      Expect_Miss (W, 4, "fib-like miss 4");
      Expect_Miss (W, 22, "fib-like miss 22");
      Expect_Miss (W, 100, "fib-like miss 100");
   end;

   ------------------------------------------------------------------
   Section ("3. Lengths that are not perfect squares");
   ------------------------------------------------------------------
   declare
      --  n = 2, 3, 5, 7, 10, 15, 17 — floor(sqrt(n)) in {1,2,3,4}
      A2  : constant Element_Array := Make_Arithmetic (1, 2, 10, 10);
      A3  : constant Element_Array := Make_Arithmetic (1, 3, 1, 1);
      A5  : constant Element_Array := Make_Arithmetic (0, 5, 0, 2);
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
   Section ("4. Perfect-square lengths (optimal m = sqrt n)");
   ------------------------------------------------------------------
   declare
      A4  : constant Element_Array := Make_Arithmetic (1, 4, 1, 1);
      A9  : constant Element_Array := Make_Arithmetic (1, 9, 10, 10);
      A16 : constant Element_Array := Make_Arithmetic (0, 16, 0, 1);
      A25 : constant Element_Array := Make_Arithmetic (1, 25, 1, 1);
   begin
      Expect_Hit (A4, 1, "n=4 first");
      Expect_Hit (A4, 4, "n=4 last");
      Expect_Miss (A4, 5, "n=4 miss");

      Expect_Hit (A9, 10, "n=9 first");
      Expect_Hit (A9, 90, "n=9 last");
      Expect_Hit (A9, 50, "n=9 mid");
      Expect_Miss (A9, 15, "n=9 miss");

      for K in 0 .. 15 loop
         Expect_Hit (A16, K, "n=16 hit" & Integer'Image (K));
      end loop;
      Expect_Miss (A16, -1, "n=16 miss -1");
      Expect_Miss (A16, 16, "n=16 miss 16");

      Expect_Hit (A25, 1, "n=25 first");
      Expect_Hit (A25, 25, "n=25 last");
      Expect_Hit (A25, 13, "n=25 mid");
      Expect_Miss (A25, 0, "n=25 miss 0");
      Expect_Miss (A25, 26, "n=25 miss 26");
   end;

   ------------------------------------------------------------------
   Section ("5. Explicit Step overload");
   ------------------------------------------------------------------
   declare
      A : constant Element_Array (1 .. 12) :=
        [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
   begin
      Expect_Hit_Step (A, 1, N (1), "step=1 first (linear)");
      Expect_Hit_Step (A, 12, N (1), "step=1 last");
      Expect_Hit_Step (A, 7, N (1), "step=1 mid");
      Expect_Miss_Step (A, 0, N (1), "step=1 miss");

      Expect_Hit_Step (A, 1, N (3), "step=3 first");
      Expect_Hit_Step (A, 12, N (3), "step=3 last");
      Expect_Hit_Step (A, 5, N (3), "step=3 mid");
      Expect_Miss_Step (A, 13, N (3), "step=3 miss high");

      Expect_Hit_Step (A, 6, N (4), "step=4 mid");
      Expect_Hit_Step (A, 12, N (5), "step=5 last");
      Expect_Hit_Step (A, 1, N (12), "step=n first");
      Expect_Hit_Step (A, 12, N (12), "step=n last");
      Expect_Hit_Step (A, 8, N (100), "step>n still finds");
      Expect_Miss_Step (A, 99, N (100), "step>n miss");
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
   Section ("9. Larger arrays (various n)");
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

      Expect_Hit (A100, 1, "n=100 first");
      Expect_Hit (A100, 100, "n=100 last");
      Expect_Hit (A100, 37, "n=100 37");
      Expect_Miss (A100, 101, "n=100 miss");

      Expect_Hit (A101, 0, "n=101 first");
      Expect_Hit (A101, 100, "n=101 last");
      Expect_Hit (A101, 50, "n=101 mid");
      Expect_Miss (A101, 101, "n=101 miss");

      Expect_Hit (A250, 1, "n=250 first");
      Expect_Hit (A250, 499, "n=250 last");
      Expect_Hit (A250, 251, "n=250 mid odd");
      Expect_Miss (A250, 2, "n=250 miss even");
      Expect_Miss (A250, 500, "n=250 miss high");
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
   Section ("11. Invalid_Argument — Max_N and Step = 0");
   ------------------------------------------------------------------
   Check (I (Integer (Max_N)) = 100_000, "Max_N is 100_000");
   Check (not Find_Raises (Make_Arithmetic (1, 3, 1, 1), 2),
          "small array does not raise");
   Check (Find_Step_Raises (Make_Arithmetic (1, 3, 1, 1), 2, N (0)),
          "Step=0 raises Invalid_Argument");
   Check (Find_Step_Raises
            (Element_Array'(1 .. 0 => <>), I (0), N (0)),
          "Step=0 raises even on empty");
   Check (not Find_Step_Raises
            (Make_Arithmetic (1, 3, 1, 1), 2, N (1)),
          "Step=1 does not raise");

   declare
      type Acc is access Element_Array;
      Big : constant Acc := new Element_Array'(1 .. Max_N + 1 => 0);
      Ok  : constant Acc := new Element_Array'(1 .. Max_N => 0);
   begin
      Check (Find_Raises (Big.all, 0),
             "length Max_N+1 raises Invalid_Argument");
      Check (Find_Step_Raises (Big.all, 0, N (10)),
             "Step overload also rejects Max_N+1");
      Check (not Find_Raises (Ok.all, 0), "length Max_N accepted");
      Expect_Hit (Ok.all, 0, "Max_N all-zero hit");
      Expect_Miss (Ok.all, 1, "Max_N all-zero miss");
      Expect_Hit_Step (Ok.all, 0, N (317), "Max_N hit with Step~sqrt");
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
      Expect_Hit_Step (A, 400, N (2), "endpoint mid step=2");
      Expect_Miss_Step (A, 450, N (2), "between step=2");
   end;

   New_Line;
   Put_Line ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image
             & " FAIL");

   if Fail_Count /= 0 then
      raise Program_Error with "test failures present";
   end if;
end Tests;
