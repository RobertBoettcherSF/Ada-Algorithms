--  Standalone test suite for Linear_Search (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Linear_Search; use Linear_Search;

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

   procedure Expect_Hit
     (A         : Element_Array;
      Key       : Integer;
      Expect_Ix : Integer;
      Label     : String)
   is
      Got : constant Integer := Find (A, Key);
   begin
      Check (Got = Expect_Ix, Label);
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

   function Find_From_Raises
     (A     : Element_Array;
      Key   : Integer;
      Start : Natural) return Boolean
   is
      Unused : Integer;
   begin
      Unused := Find_From (A, Key, Start);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Find_From_Raises;

   function Contains_Raises
     (A   : Element_Array;
      Key : Integer) return Boolean
   is
      Unused : Boolean;
   begin
      Unused := Contains (A, Key);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Contains_Raises;

   function Make_Arithmetic
     (First_Index : Natural;
      Len         : Positive;
      First_Val   : Integer;
      Step_Val    : Integer) return Element_Array
   is
      A : Element_Array (First_Index .. First_Index + Len - 1);
   begin
      for K in 0 .. Len - 1 loop
         A (First_Index + K) := First_Val + K * Step_Val;
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
   Put_Line ("Linear_Search tests");
   Put_Line ("===================");

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
      Expect_Miss (E1, 0, "empty 1..0 miss 0");
      Expect_Miss (E1, 99, "empty 1..0 miss 99");
      Expect_Miss (E5, 1, "empty 5..4 miss");
      Check (Find (E1, I (5)) = 0, "empty 1..0 sentinel 0");
      Check (Find (E5, I (5)) = 4, "empty 5..4 sentinel 4");
      Check (not Contains (E1, I (0)), "empty Contains False");
      Check (Find_From (E1, I (1), N (1)) = 0,
             "empty Find_From returns sentinel");

      Expect_Hit (S0, 42, 0, "singleton 0-based hit");
      Expect_Miss (S0, 41, "singleton 0-based miss low");
      Expect_Miss (S0, 43, "singleton 0-based miss high");
      Check (Contains (S0, I (42)), "singleton Contains True");
      Check (not Contains (S0, I (0)), "singleton Contains False");

      Expect_Hit (S1, 7, 1, "singleton 1-based hit");
      Expect_Miss (S1, 0, "singleton 1-based miss");
      Expect_Hit (S5, -3, 5, "singleton high-index hit");
      Expect_Miss (S5, 0, "singleton high-index miss");
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
      Check (Contains (A, I (6)), "small Contains mid");
      Check (not Contains (A, I (7)), "small Contains miss");
   end;

   declare
      W : constant Element_Array (0 .. 9) :=
        [0, 1, 1, 2, 3, 5, 8, 13, 21, 34];
   begin
      Expect_Hit (W, 0, 0, "fib-like first");
      Expect_Hit (W, 34, 9, "fib-like last");
      Expect_Hit (W, 8, 6, "fib-like 8");
      Expect_Hit (W, 13, 7, "fib-like 13");
      --  First occurrence of duplicate 1.
      Expect_Hit (W, 1, 1, "fib-like first dup 1");
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
      All_Same : constant Element_Array (0 .. 4) := [7, 7, 7, 7, 7];
   begin
      Expect_Hit (All_Same, 7, 0, "all-same first occurrence");
      Expect_Miss (All_Same, 6, "all-same miss");
      Check (Find_From (All_Same, I (7), N (3)) = 3,
             "all-same Find_From mid");
      Check (Find_From (All_Same, I (7), N (4)) = 4,
             "all-same Find_From last");
   end;

   ------------------------------------------------------------------
   Section ("4. Find_From — later occurrences and bounds");
   ------------------------------------------------------------------
   declare
      A : constant Element_Array (1 .. 6) := [9, 1, 9, 2, 9, 3];
   begin
      Check (Find (A, I (9)) = 1, "Find_From setup first 9");
      Check (Find_From (A, I (9), N (1)) = 1, "Find_From Start=1");
      Check (Find_From (A, I (9), N (2)) = 3, "Find_From Start=2 -> 3");
      Check (Find_From (A, I (9), N (3)) = 3, "Find_From Start=3");
      Check (Find_From (A, I (9), N (4)) = 5, "Find_From Start=4 -> 5");
      Check (Find_From (A, I (9), N (5)) = 5, "Find_From Start=5");
      Check (Find_From (A, I (9), N (6)) = Sentinel (A),
             "Find_From Start=6 miss 9");
      Check (Find_From (A, I (3), N (1)) = 6, "Find_From find last");
      Check (Find_From (A, I (1), N (3)) = Sentinel (A),
             "Find_From past earlier 1");
      Check (Find_From_Raises (A, I (1), N (0)),
             "Find_From Start below range");
      Check (Find_From_Raises (A, I (1), N (7)),
             "Find_From Start above range");
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
      Check (Find_From (A, I (-3), N (3)) = 7, "neg dup Find_From");
      Expect_Miss (A, -11, "neg miss below");
      Expect_Miss (A, 3, "neg miss between");
      Expect_Miss (A, 51, "neg miss above");
      Check (Contains (A, I (0)), "Contains zero");
      Check (not Contains (A, I (-99)), "Contains miss neg");
   end;

   ------------------------------------------------------------------
   Section ("6. Non-1 A'First index bounds");
   ------------------------------------------------------------------
   declare
      A0 : constant Element_Array (0 .. 3) := [10, 20, 30, 40];
      A7 : constant Element_Array (7 .. 10) := [1, 2, 3, 4];
   begin
      Expect_Hit (A0, 10, 0, "0-based first");
      Expect_Hit (A0, 40, 3, "0-based last");
      Expect_Miss (A0, 15, "0-based miss");
      Check (Find (A0, I (99)) = -1, "0-based sentinel -1");

      Expect_Hit (A7, 1, 7, "high-first first");
      Expect_Hit (A7, 4, 10, "high-first last");
      Expect_Miss (A7, 0, "high-first miss");
      Check (Find (A7, I (0)) = 6, "high-first sentinel 6");
      Check (Find_From (A7, I (3), N (8)) = 9, "high-first Find_From");
   end;

   ------------------------------------------------------------------
   Section ("7. Two-element and unordered permutations");
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
   Section ("8. Integer extremes");
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
   Section ("9. Larger n vs exhaustive membership");
   ------------------------------------------------------------------
   declare
      Len : constant Positive := 500;
      A   : constant Element_Array := Make_Arithmetic (1, Len, 0, 3);
      --  A(k) = 3*(k-1) for k in 1 .. 500 → 0, 3, 6, ..., 1497
   begin
      Expect_Hit (A, 0, 1, "large n first");
      Expect_Hit (A, 1497, Len, "large n last");
      Expect_Hit (A, 3 * 250, 251, "large n mid");
      Expect_Miss (A, 1, "large n miss odd");
      Expect_Miss (A, -3, "large n miss below");
      Expect_Miss (A, 1500, "large n miss above");
      Check (Contains (A, I (99)), "large Contains 99=3*33");
      Check (not Contains (A, I (100)), "large Contains miss 100");

      --  Spot-check many keys against expected formula.
      for K in 0 .. 49 loop
         declare
            Key : constant Integer := 3 * (K * 10);
            Ix  : constant Integer := Find (A, Key);
         begin
            Check (Ix = 1 + K * 10,
                   "large spot key=" & Integer'Image (Key));
         end;
      end loop;
   end;

   ------------------------------------------------------------------
   Section ("10. Random unordered arrays");
   ------------------------------------------------------------------
   declare
      Len : constant Positive := 200;
      A   : Element_Array (1 .. Len);
      Key : Integer;
      Got : Integer;
      Ref : Integer;
   begin
      for J in A'Range loop
         A (J) := Integer (Next_Mod (1_000)) - 500;
      end loop;

      --  Every present element must be found at its first index.
      for J in A'Range loop
         Key := A (J);
         Got := Find (A, Key);
         Ref := Integer (A'First) - 1;
         for K in A'Range loop
            if A (K) = Key then
               Ref := K;
               exit;
            end if;
         end loop;
         Check (Got = Ref,
                "random first-occ at " & Integer'Image (J));
      end loop;

      --  Absent keys.
      for T in 1 .. 20 loop
         Key := 10_000 + Integer (Next_Mod (1_000));
         Expect_Miss (A, Key, "random miss " & Integer'Image (T));
      end loop;
   end;

   ------------------------------------------------------------------
   Section ("11. Invalid_Argument — Max_N and Start");
   ------------------------------------------------------------------
   declare
      --  Oversized: Max_N + 1 elements (pedagogical guard only).
      Big : constant Element_Array (0 .. Max_N) := [others => 0];
   begin
      Check (Find_Raises (Big, I (0)), "Find raises on n > Max_N");
      Check (Contains_Raises (Big, I (0)),
             "Contains raises on n > Max_N");
      Check (Find_From_Raises (Big, I (0), N (0)),
             "Find_From raises on n > Max_N");
   end;

   declare
      A : constant Element_Array (2 .. 4) := [1, 2, 3];
   begin
      Check (Find_From_Raises (A, I (1), N (1)),
             "Find_From Start < First");
      Check (Find_From_Raises (A, I (1), N (5)),
             "Find_From Start > Last");
      Check (not Find_From_Raises (A, I (2), N (2)),
             "Find_From valid Start=First");
      Check (not Find_From_Raises (A, I (3), N (4)),
             "Find_From valid Start=Last");
   end;

   ------------------------------------------------------------------
   Section ("12. Contains mirrors Find");
   ------------------------------------------------------------------
   declare
      A : constant Element_Array (0 .. 5) := [-2, 0, 3, 3, 8, 9];
   begin
      Check (Contains (A, I (-2)) = (Find (A, I (-2)) /= Sentinel (A)),
             "Contains <=> Find present -2");
      Check (Contains (A, I (3)) = (Find (A, I (3)) /= Sentinel (A)),
             "Contains <=> Find present 3");
      Check (Contains (A, I (7)) = (Find (A, I (7)) /= Sentinel (A)),
             "Contains <=> Find absent 7");
      Check (Contains (A, I (9)), "Contains last");
      Check (not Contains (A, I (1)), "Contains gap");
   end;

   ------------------------------------------------------------------
   New_Line;
   Put_Line ("Results: " & Natural'Image (Pass_Count) & " PASS,"
             & Natural'Image (Fail_Count) & " FAIL");
   if Fail_Count > 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
