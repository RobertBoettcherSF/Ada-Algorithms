--  Standalone test suite for Linear_Search (SPARK port).
--  Preconditions replace exceptions; only valid call paths are exercised.
--  Sentinel is always 0 (indices are 1 .. N). No sortedness required.

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Linear_Search; use Linear_Search;

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
   function Boo (X : Boolean) return Boolean is (X);

   procedure Expect_Hit
     (A         : Element_Array;
      Key       : Integer;
      Expect_Ix : Index;
      Label     : String)
   is
      Got : constant Index := Find (A, Key);
   begin
      Check (Idx (Got) = Expect_Ix, Label);
   end Expect_Hit;

   procedure Expect_Miss
     (A     : Element_Array;
      Key   : Integer;
      Label : String)
   is
   begin
      Check (Idx (Find (A, Key)) = 0, Label);
   end Expect_Miss;

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
   Put_Line ("Linear_Search (SPARK) tests");
   Put_Line ("===========================");

   ------------------------------------------------------------------
   Section ("1. Empty and singleton");
   ------------------------------------------------------------------
   declare
      Empty : Element_Array (1 .. 0);
      One   : constant Element_Array := [1 => 42];
   begin
      Check (In_Bounds (Empty), "empty In_Bounds");
      Check (Idx (Find (Empty, 0)) = 0, "empty Find sentinel");
      Check (Idx (Find_From (Empty, 0, 0)) = 0, "empty Find_From sentinel");
      Check (not Boo (Contains (Empty, 0)), "empty Contains False");

      Check (In_Bounds (One), "singleton In_Bounds");
      Check (Idx (Find (One, 42)) = 1, "singleton hit");
      Check (Idx (Find_From (One, 42, 1)) = 1, "singleton Find_From hit");
      Expect_Miss (One, 41, "singleton miss low");
      Expect_Miss (One, 43, "singleton miss high");
      Check (Boo (Contains (One, 42)), "singleton Contains True");
      Check (not Boo (Contains (One, 0)), "singleton Contains False");
   end;

   ------------------------------------------------------------------
   Section ("2. Small arrays — first / middle / last / miss");
   ------------------------------------------------------------------
   declare
      A : constant Element_Array (1 .. 5) := [2, 4, 6, 8, 10];
   begin
      Expect_Hit (A, 2, 1, "small first");
      Expect_Hit (A, 4, 2, "small second");
      Expect_Hit (A, 6, 3, "small mid");
      Expect_Hit (A, 8, 4, "small fourth");
      Expect_Hit (A, 10, 5, "small last");
      Expect_Miss (A, 1, "small miss below");
      Expect_Miss (A, 3, "small miss between 3");
      Expect_Miss (A, 5, "small miss between 5");
      Expect_Miss (A, 7, "small miss between 7");
      Expect_Miss (A, 9, "small miss between 9");
      Expect_Miss (A, 11, "small miss above");
      Check (Boo (Contains (A, 6)), "small Contains mid");
      Check (not Boo (Contains (A, 7)), "small Contains miss");
   end;

   declare
      W : constant Element_Array (1 .. 10) :=
        [0, 1, 1, 2, 3, 5, 8, 13, 21, 34];
   begin
      Expect_Hit (W, 0, 1, "fib-like first");
      Expect_Hit (W, 34, 10, "fib-like last");
      Expect_Hit (W, 8, 7, "fib-like 8");
      Expect_Hit (W, 13, 8, "fib-like 13");
      --  First occurrence of duplicate 1.
      Expect_Hit (W, 1, 2, "fib-like first dup 1");
      Expect_Miss (W, -1, "fib-like miss -1");
      Expect_Miss (W, 4, "fib-like miss 4");
      Expect_Miss (W, 22, "fib-like miss 22");
      Expect_Miss (W, 100, "fib-like miss 100");
   end;

   ------------------------------------------------------------------
   Section ("3. Duplicates — first occurrence");
   ------------------------------------------------------------------
   declare
      D : constant Element_Array (1 .. 8) :=
        [1, 2, 2, 2, 3, 4, 4, 5];
   begin
      Expect_Hit (D, 2, 2, "dup 2 first at 2");
      Expect_Hit (D, 4, 6, "dup 4 first at 6");
      Expect_Hit (D, 1, 1, "dup unique first");
      Expect_Hit (D, 5, 8, "dup unique last");
      Expect_Miss (D, 0, "dup miss 0");
      Expect_Miss (D, 9, "dup miss 9");
   end;

   declare
      All_Same : constant Element_Array (1 .. 5) := [7, 7, 7, 7, 7];
   begin
      Expect_Hit (All_Same, 7, 1, "all-same first occurrence");
      Expect_Miss (All_Same, 6, "all-same miss");
      Check (Idx (Find_From (All_Same, 7, 3)) = 3,
             "all-same Find_From mid");
      Check (Idx (Find_From (All_Same, 7, 5)) = 5,
             "all-same Find_From last");
   end;

   ------------------------------------------------------------------
   Section ("4. Find_From — later occurrences");
   ------------------------------------------------------------------
   declare
      A : constant Element_Array (1 .. 6) := [9, 1, 9, 2, 9, 3];
   begin
      Check (Idx (Find (A, 9)) = 1, "Find_From setup first 9");
      Check (Idx (Find_From (A, 9, 1)) = 1, "Find_From Start=1");
      Check (Idx (Find_From (A, 9, 2)) = 3, "Find_From Start=2 -> 3");
      Check (Idx (Find_From (A, 9, 3)) = 3, "Find_From Start=3");
      Check (Idx (Find_From (A, 9, 4)) = 5, "Find_From Start=4 -> 5");
      Check (Idx (Find_From (A, 9, 5)) = 5, "Find_From Start=5");
      Check (Idx (Find_From (A, 9, 6)) = 0, "Find_From Start=6 miss 9");
      Check (Idx (Find_From (A, 3, 1)) = 6, "Find_From find last");
      Check (Idx (Find_From (A, 1, 3)) = 0, "Find_From past earlier 1");
   end;

   ------------------------------------------------------------------
   Section ("5. Negatives, zero, mixed signed");
   ------------------------------------------------------------------
   declare
      A : constant Element_Array (1 .. 7) :=
        [-10, -3, 0, 1, 2, 50, -3];
   begin
      Expect_Hit (A, -10, 1, "neg first");
      Expect_Hit (A, 0, 3, "zero hit");
      Expect_Hit (A, 50, 6, "pos large");
      Expect_Hit (A, -3, 2, "neg dup first");
      Check (Idx (Find_From (A, -3, 3)) = 7, "neg dup Find_From");
      Expect_Miss (A, -11, "neg miss below");
      Expect_Miss (A, 3, "neg miss between");
      Expect_Miss (A, 51, "neg miss above");
      Check (Boo (Contains (A, 0)), "Contains zero");
      Check (not Boo (Contains (A, -99)), "Contains miss neg");
   end;

   ------------------------------------------------------------------
   Section ("6. Two-element and unordered permutations");
   ------------------------------------------------------------------
   declare
      T1 : constant Element_Array (1 .. 2) := [1, 2];
      T2 : constant Element_Array (1 .. 2) := [2, 1];
      T3 : constant Element_Array (1 .. 2) := [5, 5];
   begin
      Expect_Hit (T1, 1, 1, "two asc first");
      Expect_Hit (T1, 2, 2, "two asc last");
      Expect_Miss (T1, 0, "two asc miss");
      Expect_Hit (T2, 2, 1, "two desc first");
      Expect_Hit (T2, 1, 2, "two desc last");
      Expect_Hit (T3, 5, 1, "two equal first");
   end;

   declare
      --  Unordered — linear search does not require sorted input.
      U : constant Element_Array (1 .. 6) := [40, 10, 30, 20, 50, 0];
   begin
      Expect_Hit (U, 40, 1, "unordered first");
      Expect_Hit (U, 0, 6, "unordered last");
      Expect_Hit (U, 30, 3, "unordered mid");
      Expect_Miss (U, 15, "unordered miss");
      Expect_Miss (U, -1, "unordered miss neg");
   end;

   ------------------------------------------------------------------
   Section ("7. Integer extremes");
   ------------------------------------------------------------------
   declare
      A : constant Element_Array (1 .. 4) :=
        [Integer'First, -1, 0, Integer'Last];
   begin
      Expect_Hit (A, Integer'First, 1, "Integer'First hit");
      Expect_Hit (A, Integer'Last, 4, "Integer'Last hit");
      Expect_Hit (A, -1, 2, "near-min hit");
      Expect_Hit (A, 0, 3, "zero among extremes");
      Expect_Miss (A, 1, "extremes miss 1");
   end;

   ------------------------------------------------------------------
   Section ("8. Max_N vs exhaustive first-occurrence");
   ------------------------------------------------------------------
   declare
      N : constant := Max_N;
      A : Element_Array (1 .. N);
   begin
      for I in A'Range loop
         A (I) := I * 3;
      end loop;
      Check (In_Bounds (A), "Max_N In_Bounds");

      Expect_Hit (A, 3, 1, "Max_N first");
      Expect_Hit (A, 3 * N, Index (N), "Max_N last");
      Expect_Hit (A, 3 * 32, 32, "Max_N mid");
      Expect_Miss (A, 1, "Max_N miss odd");
      Expect_Miss (A, -3, "Max_N miss below");
      Expect_Miss (A, 3 * N + 3, "Max_N miss above");
      Check (Boo (Contains (A, 99)), "Max_N Contains 99=3*33");
      Check (not Boo (Contains (A, 100)), "Max_N Contains miss 100");

      for K in 0 .. 15 loop
         declare
            Key : constant Integer := 3 * (K * 4 + 1);
            Ix  : constant Index := Find (A, Key);
         begin
            Check (Idx (Ix) = Index (K * 4 + 1),
                   "Max_N spot key=" & Integer'Image (Key));
         end;
      end loop;
   end;

   ------------------------------------------------------------------
   Section ("9. Random unordered arrays");
   ------------------------------------------------------------------
   declare
      N   : constant := Max_N;
      A   : Element_Array (1 .. N);
      Key : Integer;
      Got : Index;
      Ref : Index;
   begin
      Seed := 42;
      for J in A'Range loop
         A (J) := Integer (Next_Mod (1_000)) - 500;
      end loop;

      --  Every present element must be found at its first index.
      for J in A'Range loop
         Key := A (J);
         Got := Find (A, Key);
         Ref := 0;
         for K in A'Range loop
            if A (K) = Key then
               Ref := K;
               exit;
            end if;
         end loop;
         Check (Idx (Got) = Idx (Ref),
                "random first-occ at " & Integer'Image (J));
      end loop;

      --  Absent keys.
      for T in 1 .. 20 loop
         Key := 10_000 + Integer (Next_Mod (1_000));
         Expect_Miss (A, Key, "random miss " & Integer'Image (T));
      end loop;
   end;

   ------------------------------------------------------------------
   Section ("10. Contains mirrors Find; In_Bounds helper");
   ------------------------------------------------------------------
   declare
      A   : constant Element_Array (1 .. 6) := [-2, 0, 3, 3, 8, 9];
      Cap : Element_Array (1 .. Max_N);
   begin
      Check (Boo (Contains (A, -2)) = (Find (A, -2) > 0),
             "Contains <=> Find present -2");
      Check (Boo (Contains (A, 3)) = (Find (A, 3) > 0),
             "Contains <=> Find present 3");
      Check (Boo (Contains (A, 7)) = (Find (A, 7) > 0),
             "Contains <=> Find absent 7");
      Check (Boo (Contains (A, 9)), "Contains last");
      Check (not Boo (Contains (A, 1)), "Contains gap");
      Check (Idx (Find (A, 3)) = 3, "Contains suite first dup 3");

      for I in Cap'Range loop
         Cap (I) := I;
      end loop;
      Check (In_Bounds (Cap), "Cap In_Bounds at Max_N");
      Check (Nat (Max_N) = 64, "Max_N = 64");
      Check (Int (Find (A, 8)) = 5, "Find 8 at 5");
   end;

   ------------------------------------------------------------------
   Section ("11. Find_From at Max_N scale");
   ------------------------------------------------------------------
   declare
      N : constant := Max_N;
      A : Element_Array (1 .. N);
   begin
      for I in A'Range loop
         A (I) := ((I - 1) rem 5) + 1;  --  repeating 1..5
      end loop;

      Check (Idx (Find (A, 1)) = 1, "pattern Find 1");
      Check (Idx (Find (A, 5)) = 5, "pattern Find 5");
      Check (Idx (Find_From (A, 1, 2)) = 6, "pattern Find_From 1 from 2");
      Check (Idx (Find_From (A, 5, 6)) = 10, "pattern Find_From 5 from 6");
      Check (Idx (Find_From (A, 3, N)) = 0
             or else A (Find_From (A, 3, N)) = 3,
             "pattern Find_From last cell");
      --  Last cell is ((64-1) rem 5)+1 = 4; key 3 from last is miss.
      Check (Idx (Find_From (A, 3, N)) = 0, "pattern miss 3 at last");
      Check (Idx (Find_From (A, 4, N)) = Index (N), "pattern hit 4 at last");
   end;

   New_Line;
   Put_Line ("Results: "
             & Natural'Image (Pass_Count) & " PASS,"
             & Natural'Image (Fail_Count) & " FAIL");
   if Fail_Count /= 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
