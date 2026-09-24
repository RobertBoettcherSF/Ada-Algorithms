--  Standalone test suite for Brute_Force_Search (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Brute_Force_Search; use Brute_Force_Search;

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
   function N (X : Natural)  return Natural  is (X);
   function P (X : Positive) return Positive is (X);

   function Sentinel (A : Element_Array) return Integer is
     (Integer (A'First) - 1);

   function Is_Prime_By_Divisor (X : Positive) return Boolean is
     (X > 1 and then Find_Divisor (X) = X);

   function Factorial (K : Natural) return Natural is
      Acc : Natural := 1;
   begin
      for J in 1 .. K loop
         Acc := Acc * J;
      end loop;
      return Acc;
   end Factorial;

   ---------------------------------------------------------------------------
   -- Exception probes
   ---------------------------------------------------------------------------

   function Linear_Raises (A : Element_Array; Key : Integer) return Boolean is
      Unused : Integer;
   begin
      Unused := Linear_Search (A, Key);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Linear_Raises;

   function Subset_Raises
     (A : Element_Array; Target : Integer) return Boolean
   is
      Unused : Boolean;
   begin
      Unused := Subset_Sum_Exists (A, Target);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Subset_Raises;

   function Count_Perm_Raises (K : Natural) return Boolean is
      Unused : Natural;
   begin
      Unused := Count_Permutations (K);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Count_Perm_Raises;

   function Find_Perm_Raises (Target : Element_Array) return Boolean is
      Unused : Natural;
   begin
      Unused := Find_Permutation (Target);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Find_Perm_Raises;

   function Enum_Perm_Raises (K : Natural) return Boolean is
      Unused : Natural;
   begin
      Enumerate_Permutations (K, Unused);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Enum_Perm_Raises;

begin
   Put_Line ("Brute_Force_Search — Ada 2023 educational test suite");
   Put_Line ("====================================================");

   ---------------------------------------------------------------------------
   Section ("Find_Divisor — basics");
   ---------------------------------------------------------------------------

   Check (Find_Divisor (P (1)) = 1, "N=1 returns 1");
   Check (Find_Divisor (P (2)) = 2, "prime 2 → 2");
   Check (Find_Divisor (P (3)) = 3, "prime 3 → 3");
   Check (Find_Divisor (P (4)) = 2, "4 → 2");
   Check (Find_Divisor (P (5)) = 5, "prime 5 → 5");
   Check (Find_Divisor (P (6)) = 2, "6 → 2");
   Check (Find_Divisor (P (7)) = 7, "prime 7 → 7");
   Check (Find_Divisor (P (8)) = 2, "8 → 2");
   Check (Find_Divisor (P (9)) = 3, "9 → 3");
   Check (Find_Divisor (P (10)) = 2, "10 → 2");
   Check (Find_Divisor (P (15)) = 3, "15 → 3");
   Check (Find_Divisor (P (21)) = 3, "21 → 3");
   Check (Find_Divisor (P (25)) = 5, "25 → 5");
   Check (Find_Divisor (P (27)) = 3, "27 → 3");
   Check (Find_Divisor (P (35)) = 5, "35 → 5");
   Check (Find_Divisor (P (49)) = 7, "49 → 7");
   Check (Find_Divisor (P (91)) = 7, "91 = 7*13 → 7");
   Check (Find_Divisor (P (97)) = 97, "prime 97 → 97");
   Check (Find_Divisor (P (100)) = 2, "100 → 2");
   Check (Find_Divisor (P (121)) = 11, "121 → 11");

   ---------------------------------------------------------------------------
   Section ("Find_Divisor — primes and composites batch");
   ---------------------------------------------------------------------------

   declare
      Primes : constant array (Positive range <>) of Positive :=
        [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47,
         53, 59, 61, 67, 71, 73, 79, 83, 89, 97];
   begin
      for K in Primes'Range loop
         Check
           (Find_Divisor (Primes (K)) = Natural (Primes (K)),
            "prime " & Primes (K)'Image & " → self");
      end loop;
   end;

   declare
      Composites : constant array (Positive range <>) of Positive :=
        [4, 6, 8, 9, 10, 12, 14, 15, 16, 18, 20, 22, 24, 25, 26,
         27, 28, 30, 32, 33, 34, 36, 38, 39, 40];
   begin
      for K in Composites'Range loop
         declare
            D : constant Natural := Find_Divisor (Composites (K));
         begin
            Check
              (D >= 2
                 and then D < Natural (Composites (K))
                 and then Composites (K) rem D = 0,
               "composite " & Composites (K)'Image
                 & " proper divisor " & D'Image);
         end;
      end loop;
   end;

   Check (Is_Prime_By_Divisor (P (2)),  "Is_Prime helper 2");
   Check (Is_Prime_By_Divisor (P (13)), "Is_Prime helper 13");
   Check (not Is_Prime_By_Divisor (P (1)),  "1 is not prime");
   Check (not Is_Prime_By_Divisor (P (9)),  "9 is not prime");
   Check (not Is_Prime_By_Divisor (P (100)), "100 is not prime");

   ---------------------------------------------------------------------------
   Section ("Linear_Search — hits and misses");
   ---------------------------------------------------------------------------

   declare
      A : constant Element_Array (1 .. 6) := [40, 10, 30, 20, 50, 0];
   begin
      Check (Linear_Search (A, I (30)) = 3, "hit 30 at index 3");
      Check (Linear_Search (A, I (40)) = 1, "hit 40 at first");
      Check (Linear_Search (A, I (0)) = 6,  "hit 0 at last");
      Check (Linear_Search (A, I (10)) = 2, "hit 10");
      Check (Linear_Search (A, I (50)) = 5, "hit 50");
      Check (Linear_Search (A, I (20)) = 4, "hit 20");
      Check (Linear_Search (A, I (15)) = Sentinel (A), "miss 15");
      Check (Linear_Search (A, I (99)) = Sentinel (A), "miss 99");
      Check (Linear_Search (A, I (-1)) = Sentinel (A), "miss -1");
   end;

   declare
      Empty : Element_Array (1 .. 0);
   begin
      Check
        (Linear_Search (Empty, I (0)) = Sentinel (Empty),
         "empty array miss");
   end;

   declare
      Z : constant Element_Array (0 .. 3) := [7, 8, 9, 7];
   begin
      Check (Linear_Search (Z, I (7)) = 0, "0-based first hit");
      Check (Linear_Search (Z, I (9)) = 2, "0-based middle");
      Check (Linear_Search (Z, I (8)) = 1, "0-based index 1");
      Check (Linear_Search (Z, I (1)) = Sentinel (Z), "0-based miss");
   end;

   declare
      Dup : constant Element_Array (1 .. 5) := [1, 2, 2, 2, 3];
   begin
      Check (Linear_Search (Dup, I (2)) = 2, "first of duplicates");
      Check (Linear_Search (Dup, I (1)) = 1, "leading unique");
      Check (Linear_Search (Dup, I (3)) = 5, "trailing unique");
   end;

   declare
      Neg : constant Element_Array (1 .. 4) := [-5, -1, 0, 4];
   begin
      Check (Linear_Search (Neg, I (-5)) = 1, "negative key hit");
      Check (Linear_Search (Neg, I (-1)) = 2, "negative mid");
      Check (Linear_Search (Neg, I (0)) = 3,  "zero key");
      Check (Linear_Search (Neg, I (-9)) = Sentinel (Neg), "neg miss");
   end;

   declare
      One : constant Element_Array (5 .. 5) := [42];
   begin
      Check (Linear_Search (One, I (42)) = 5, "singleton hit odd bounds");
      Check
        (Linear_Search (One, I (0)) = Sentinel (One),
         "singleton miss odd bounds");
   end;

   ---------------------------------------------------------------------------
   Section ("Linear_Search — Invalid_Argument");
   ---------------------------------------------------------------------------

   declare
      Big : constant Element_Array (1 .. Max_Linear_N + 1) := [others => 0];
   begin
      Check (Linear_Raises (Big, I (0)), "Linear_Search over Max_Linear_N");
   end;

   declare
      Ok : constant Element_Array (1 .. 3) := [1, 2, 3];
   begin
      Check (not Linear_Raises (Ok, I (2)), "Linear_Search accepts small n");
   end;

   ---------------------------------------------------------------------------
   Section ("Subset_Sum_Exists — small instances");
   ---------------------------------------------------------------------------

   declare
      Empty : Element_Array (1 .. 0);
   begin
      Check (Subset_Sum_Exists (Empty, I (0)), "empty → sum 0 true");
      Check (not Subset_Sum_Exists (Empty, I (1)), "empty → sum 1 false");
      Check (not Subset_Sum_Exists (Empty, I (-1)), "empty → sum -1 false");
   end;

   declare
      A : constant Element_Array (1 .. 1) := [5];
   begin
      Check (Subset_Sum_Exists (A, I (0)), "singleton empty subset");
      Check (Subset_Sum_Exists (A, I (5)), "singleton full set");
      Check (not Subset_Sum_Exists (A, I (4)), "singleton miss");
      Check (not Subset_Sum_Exists (A, I (6)), "singleton miss high");
   end;

   declare
      A : constant Element_Array (1 .. 3) := [3, 1, 4];
   begin
      Check (Subset_Sum_Exists (A, I (0)),  "{3,1,4} empty");
      Check (Subset_Sum_Exists (A, I (1)),  "{1}");
      Check (Subset_Sum_Exists (A, I (3)),  "{3}");
      Check (Subset_Sum_Exists (A, I (4)),  "{4}");
      Check (Subset_Sum_Exists (A, I (5)),  "{1,4}");
      Check (Subset_Sum_Exists (A, I (7)),  "{3,4}");
      Check (Subset_Sum_Exists (A, I (8)),  "{3,1,4}");
      Check (not Subset_Sum_Exists (A, I (2)),  "no subset = 2");
      Check (not Subset_Sum_Exists (A, I (6)),  "no subset = 6");
      Check (not Subset_Sum_Exists (A, I (9)),  "no subset = 9");
   end;

   declare
      A : constant Element_Array (0 .. 3) := [2, 3, 5, 7];
   begin
      Check (Subset_Sum_Exists (A, I (10)), "0-based {3,7}");
      Check (Subset_Sum_Exists (A, I (17)), "0-based full sum");
      Check (Subset_Sum_Exists (A, I (2)),  "0-based {2}");
      Check (not Subset_Sum_Exists (A, I (1)), "0-based miss 1");
      Check (not Subset_Sum_Exists (A, I (18)), "0-based miss 18");
   end;

   declare
      A : constant Element_Array (1 .. 4) := [-2, 3, -1, 5];
   begin
      Check (Subset_Sum_Exists (A, I (0)),  "negatives empty");
      Check (Subset_Sum_Exists (A, I (-2)), "{-2}");
      Check (Subset_Sum_Exists (A, I (-3)), "{-2,-1}");
      Check (Subset_Sum_Exists (A, I (5)),  "{5}");
      Check (Subset_Sum_Exists (A, I (2)),  "{-1,3}");
      Check (Subset_Sum_Exists (A, I (5)),  "{3,-1,?,} ok");
      Check (not Subset_Sum_Exists (A, I (100)), "negatives miss large");
   end;

   declare
      A : constant Element_Array (1 .. 5) := [1, 2, 4, 8, 16];
   begin
      --  All sums 0 .. 31 exist (binary basis).
      for T in 0 .. 31 loop
         Check
           (Subset_Sum_Exists (A, I (T)),
            "powers-of-two sum " & T'Image);
      end loop;
      Check (not Subset_Sum_Exists (A, I (32)), "powers miss 32");
      Check (not Subset_Sum_Exists (A, I (-1)), "powers miss -1");
   end;

   ---------------------------------------------------------------------------
   Section ("Subset_Sum_Exists — Invalid_Argument");
   ---------------------------------------------------------------------------

   declare
      Big : constant Element_Array (1 .. Max_Subset_N + 1) := [others => 1];
   begin
      Check (Subset_Raises (Big, I (0)), "subset over Max_Subset_N");
   end;

   declare
      Ok : constant Element_Array (1 .. Max_Subset_N) := [others => 0];
   begin
      Check
        (not Subset_Raises (Ok, I (0)),
         "subset accepts Max_Subset_N");
      Check (Subset_Sum_Exists (Ok, I (0)), "all zeros → 0");
      Check (not Subset_Sum_Exists (Ok, I (1)), "all zeros miss 1");
   end;

   ---------------------------------------------------------------------------
   Section ("Count_Permutations / Enumerate_Permutations");
   ---------------------------------------------------------------------------

   Check (Count_Permutations (N (0)) = 1, "0! = 1");
   Check (Count_Permutations (N (1)) = 1, "1! = 1");
   Check (Count_Permutations (N (2)) = 2, "2! = 2");
   Check (Count_Permutations (N (3)) = 6, "3! = 6");
   Check (Count_Permutations (N (4)) = 24, "4! = 24");
   Check (Count_Permutations (N (5)) = 120, "5! = 120");
   Check (Count_Permutations (N (6)) = 720, "6! = 720");
   Check (Count_Permutations (N (7)) = 5_040, "7! = 5040");
   Check (Count_Permutations (N (8)) = 40_320, "8! = 40320");

   for K in 0 .. Max_Perm_N loop
      Check
        (Count_Permutations (K) = Factorial (K),
         "Count matches Factorial for n=" & K'Image);
   end loop;

   declare
      C : Natural;
   begin
      for K in 0 .. 5 loop
         Enumerate_Permutations (K, C);
         Check
           (C = Factorial (K),
            "Enumerate_Permutations n=" & K'Image);
      end loop;
   end;

   Check (Count_Perm_Raises (N (9)), "Count_Permutations n=9 raises");
   Check (Count_Perm_Raises (N (20)), "Count_Permutations n=20 raises");
   Check (Enum_Perm_Raises (N (9)), "Enumerate_Permutations n=9 raises");
   Check (not Count_Perm_Raises (N (8)), "Count accepts Max_Perm_N");

   ---------------------------------------------------------------------------
   Section ("Find_Permutation — ranks");
   ---------------------------------------------------------------------------

   declare
      Empty : Element_Array (1 .. 0);
   begin
      Check (Find_Permutation (Empty) = 1, "empty perm rank 1");
   end;

   declare
      T1 : constant Element_Array := [1];
   begin
      Check (Find_Permutation (T1) = 1, "singleton [1] rank 1");
   end;

   declare
      Bad1 : constant Element_Array := [2];
   begin
      Check (Find_Permutation (Bad1) = 0, "[2] not perm of 1..1");
   end;

   --  Permutations of 1..2 in lex order: [1,2]=1, [2,1]=2
   Check (Find_Permutation ([1, 2]) = 1, "[1,2] rank 1");
   Check (Find_Permutation ([2, 1]) = 2, "[2,1] rank 2");
   Check (Find_Permutation ([1, 1]) = 0, "[1,1] invalid");
   Check (Find_Permutation ([1, 3]) = 0, "[1,3] invalid for n=2");

   --  Permutations of 1..3:
   --  1:123  2:132  3:213  4:231  5:312  6:321
   Check (Find_Permutation ([1, 2, 3]) = 1, "[1,2,3] rank 1");
   Check (Find_Permutation ([1, 3, 2]) = 2, "[1,3,2] rank 2");
   Check (Find_Permutation ([2, 1, 3]) = 3, "[2,1,3] rank 3");
   Check (Find_Permutation ([2, 3, 1]) = 4, "[2,3,1] rank 4");
   Check (Find_Permutation ([3, 1, 2]) = 5, "[3,1,2] rank 5");
   Check (Find_Permutation ([3, 2, 1]) = 6, "[3,2,1] rank 6");
   Check (Find_Permutation ([1, 2, 2]) = 0, "duplicate invalid");
   Check (Find_Permutation ([0, 1, 2]) = 0, "zero invalid");
   Check (Find_Permutation ([1, 2, 4]) = 0, "out of range invalid");

   --  First and last of 1..4
   Check (Find_Permutation ([1, 2, 3, 4]) = 1,  "[1,2,3,4] first");
   Check (Find_Permutation ([4, 3, 2, 1]) = 24, "[4,3,2,1] last");
   Check (Find_Permutation ([1, 2, 4, 3]) = 2,  "[1,2,4,3] second");
   Check (Find_Permutation ([2, 1, 3, 4]) = 7,  "[2,1,3,4] rank 7");

   --  0-based bounds still work (values matter, not indices)
   declare
      T : constant Element_Array (0 .. 2) := [2, 3, 1];
   begin
      Check (Find_Permutation (T) = 4, "0-based [2,3,1] rank 4");
   end;

   declare
      Too_Long : constant Element_Array (1 .. 9) := [1, 2, 3, 4, 5, 6, 7, 8, 9];
   begin
      Check (Find_Perm_Raises (Too_Long), "Find_Permutation n=9 raises");
   end;

   declare
      Ok8 : constant Element_Array (1 .. 8) := [1, 2, 3, 4, 5, 6, 7, 8];
   begin
      Check (not Find_Perm_Raises (Ok8), "Find accepts n=8");
      Check (Find_Permutation (Ok8) = 1, "identity 1..8 rank 1");
   end;

   declare
      Last8 : constant Element_Array (1 .. 8) := [8, 7, 6, 5, 4, 3, 2, 1];
   begin
      Check
        (Find_Permutation (Last8) = 40_320,
         "reverse 1..8 is last rank");
   end;

   ---------------------------------------------------------------------------
   Section ("Cross-checks and invariants");
   ---------------------------------------------------------------------------

   --  Every Find_Divisor result divides N and is minimal in 2..result.
   for X in 1 .. 60 loop
      declare
         D : constant Natural := Find_Divisor (X);
      begin
         Check (X rem D = 0, "divides: " & X'Image & " /" & D'Image);
         if X > 1 then
            Check (D >= 2, "divisor >= 2 for " & X'Image);
            declare
               Minimal : Boolean := True;
            begin
               for C in 2 .. D - 1 loop
                  if X rem C = 0 then
                     Minimal := False;
                  end if;
               end loop;
               Check (Minimal, "minimal divisor for " & X'Image);
            end;
         end if;
      end;
   end loop;

   --  Linear_Search agrees with manual scan on a fixed array.
   declare
      A : constant Element_Array (1 .. 10) :=
        [9, 7, 5, 3, 1, 2, 4, 6, 8, 0];
   begin
      for Key in 0 .. 12 loop
         declare
            Got : constant Integer := Linear_Search (A, Key);
            Exp : Integer := Sentinel (A);
         begin
            for J in A'Range loop
               if A (J) = Key then
                  Exp := J;
                  exit;
               end if;
            end loop;
            Check (Got = Exp, "oracle linear key=" & Key'Image);
         end;
      end loop;
   end;

   --  Subset sum: total sum always achievable; sum+1 never (nonneg).
   declare
      A : constant Element_Array := [1, 3, 5, 7];
      S : Integer := 0;
   begin
      for J in A'Range loop
         S := S + A (J);
      end loop;
      Check (Subset_Sum_Exists (A, S), "full sum achievable");
      Check (not Subset_Sum_Exists (A, S + 1), "full sum + 1 miss");
      Check (Subset_Sum_Exists (A, I (0)), "zero always (empty)");
   end;

   --  Count_Permutations consistency with Enumerate
   declare
      C1, C2 : Natural;
   begin
      for K in 0 .. 6 loop
         C1 := Count_Permutations (K);
         Enumerate_Permutations (K, C2);
         Check (C1 = C2, "Count vs Enumerate n=" & K'Image);
      end loop;
   end;

   --  Every lex rank for n=3 is unique and covers 1..6
   declare
      Seen : array (1 .. 6) of Boolean := [others => False];
      Perms : constant array (1 .. 6) of Element_Array (1 .. 3) :=
        [[1, 2, 3], [1, 3, 2], [2, 1, 3],
         [2, 3, 1], [3, 1, 2], [3, 2, 1]];
   begin
      for K in Perms'Range loop
         declare
            R : constant Natural := Find_Permutation (Perms (K));
         begin
            Check (R in 1 .. 6, "rank in range for perm #" & K'Image);
            if R in 1 .. 6 then
               Check (not Seen (R), "unique rank " & R'Image);
               Seen (R) := True;
               Check (R = K, "rank equals lex index " & K'Image);
            end if;
         end;
      end loop;
      for R in Seen'Range loop
         Check (Seen (R), "all ranks covered " & R'Image);
      end loop;
   end;

   ---------------------------------------------------------------------------
   Section ("Capacity constants");
   ---------------------------------------------------------------------------

   Check (N (Max_Linear_N) = N (100_000), "Max_Linear_N = 100000");
   Check (N (Max_Subset_N) = N (20), "Max_Subset_N = 20");
   Check (N (Max_Perm_N) = N (8), "Max_Perm_N = 8");

   ---------------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------------

   New_Line;
   Put_Line ("====================================================");
   Put_Line
     ("Result: " & Pass_Count'Image & " passed," & Fail_Count'Image
      & " failed");
   if Fail_Count = 0 then
      Put_Line ("ALL PASS");
   else
      Put_Line ("SOME FAILURES");
   end if;
end Tests;
