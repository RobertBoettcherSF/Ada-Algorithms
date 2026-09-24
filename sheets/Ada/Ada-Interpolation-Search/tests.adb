--  Standalone test suite for Interpolation_Search (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Interpolation_Search; use Interpolation_Search;

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

   --  Uniform arithmetic sequence A(First + k) = First_Val + k * Step.
   function Make_Arithmetic
     (First_Index : Natural;
      Len         : Positive;
      First_Val   : Integer;
      Step        : Positive) return Element_Array
   is
      A : Element_Array (First_Index .. First_Index + Len - 1);
   begin
      for K in 0 .. Len - 1 loop
         A (First_Index + K) := First_Val + K * Step;
      end loop;
      return A;
   end Make_Arithmetic;

begin
   Put_Line ("Interpolation_Search tests");
   Put_Line ("==========================");

   ------------------------------------------------------------------
   Section ("1. Empty and singleton");
   ------------------------------------------------------------------
   declare
      --  Empty ranges must keep both bounds in Natural (First > Last).
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
   Section ("2. Uniform arithmetic sequence (best case)");
   ------------------------------------------------------------------
   declare
      A : constant Element_Array := Make_Arithmetic (1, 20, 10, 10);
      --  10,20,...,200
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
   end;

   declare
      Z : constant Element_Array := Make_Arithmetic (0, 16, 0, 1);
      --  0..15 at indices 0..15 — ideal uniform
   begin
      for K in 0 .. 15 loop
         Expect_Hit (Z, K, "dense hit" & Integer'Image (K));
      end loop;
      Expect_Miss (Z, -1, "dense miss -1");
      Expect_Miss (Z, 16, "dense miss 16");
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
        [1, 3, 5, 6, 7, 9, 14, 15, 17, 19];
   begin
      Expect_Hit (W, 1, "wiki-like first");
      Expect_Hit (W, 19, "wiki-like last");
      Expect_Hit (W, 7, "wiki-like 7");
      Expect_Hit (W, 14, "wiki-like 14");
      Expect_Miss (W, 0, "wiki-like miss 0");
      Expect_Miss (W, 8, "wiki-like miss 8");
      Expect_Miss (W, 20, "wiki-like miss 20");
      Expect_Miss (W, 12, "wiki-like miss 12");
   end;

   ------------------------------------------------------------------
   Section ("4. Duplicates");
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

   ------------------------------------------------------------------
   Section ("5. Clustered / non-uniform values");
   ------------------------------------------------------------------
   declare
      --  Clustered low values then a jump (harder for interpolation).
      C : constant Element_Array (1 .. 10) :=
        [1, 1, 1, 1, 2, 2, 2, 100, 1000, 10_000];
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
   end;

   declare
      --  Exponential-ish growth (near worst-case shape).
      E : constant Element_Array (0 .. 7) :=
        [1, 2, 4, 8, 16, 32, 64, 128];
   begin
      Expect_Hit (E, 1, "exp hit 1");
      Expect_Hit (E, 8, "exp hit 8");
      Expect_Hit (E, 64, "exp hit 64");
      Expect_Hit (E, 128, "exp hit 128");
      Expect_Miss (E, 3, "exp miss 3");
      Expect_Miss (E, 90, "exp miss 90");
      Expect_Miss (E, 256, "exp miss 256");
   end;

   ------------------------------------------------------------------
   Section ("6. Negatives and mixed signs");
   ------------------------------------------------------------------
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

   ------------------------------------------------------------------
   Section ("7. Index bases (0-based vs 1-based vs offset)");
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
   Section ("8. Larger uniform array");
   ------------------------------------------------------------------
   declare
      Len : constant := 500;
      A   : constant Element_Array := Make_Arithmetic (1, Len, 1, 1);
   begin
      Expect_Hit (A, 1, "large first");
      Expect_Hit (A, Len, "large last");
      Expect_Hit (A, 250, "large mid");
      Expect_Hit (A, 17, "large 17");
      Expect_Hit (A, 499, "large 499");
      Expect_Miss (A, 0, "large miss 0");
      Expect_Miss (A, Len + 1, "large miss above");
      Expect_Miss (A, -5, "large miss neg");
   end;

   ------------------------------------------------------------------
   Section ("9. Two- and three-element edge cases");
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
   Section ("10. Invalid_Argument and Max_N");
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
   Section ("11. Boundary keys equal to endpoints");
   ------------------------------------------------------------------
   declare
      A : constant Element_Array (1 .. 8) :=
        [100, 200, 300, 400, 500, 600, 700, 800];
   begin
      Expect_Hit (A, 100, "endpoint low");
      Expect_Hit (A, 800, "endpoint high");
      Expect_Miss (A, 99, "just below low");
      Expect_Miss (A, 801, "just above high");
   end;

   New_Line;
   Put_Line ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image
             & " FAIL");

   if Fail_Count /= 0 then
      raise Program_Error with "test failures present";
   end if;
end Tests;
