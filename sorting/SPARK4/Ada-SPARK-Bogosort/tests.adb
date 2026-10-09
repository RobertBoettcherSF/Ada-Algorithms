--  Standalone test suite for Bogosort (SPARK port): bounded random
--  shuffle with an explicit outcome (Sorted / Gave_Up).
--  Preconditions replace exceptions; only valid call paths are exercised.
--  Any A'First (section 9); Max_N = 8. Every Sort call outside section 11
--  must end Sorted (P (Gave_Up) <= 1e-9 per call for an ideal shuffle).
--  Sections 10 and 11 pin the exact shuffle counts, final arrays and final
--  seeds for fixed seeds; the expected values come from the independent
--  model tests/shuffle_counts.py (written from the spec comment).

pragma Ada_2022;

with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Bogosort; use Bogosort;

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

   --  Generator state for all Sort calls outside sections 10 and 11.
   Sort_Seed : Seed_Type := 2026;

   procedure Run (A : in out Element_Array) is
      R : Outcome;
      N : Natural;
   begin
      Sort (A, Sort_Seed, R, N);
      Check (R = Sorted and then N <= Max_Shuffles,
             "outcome Sorted after" & N'Image & " shuffles");
   end Run;

   procedure Expect_Sorted (Src : Element_Array; Label : String) is
      A : Element_Array := Copy_Of (Src);
      R : Element_Array := Copy_Of (Src);
      O : constant Element_Array := Copy_Of (Src);
   begin
      Run (A);
      Reference_Sort (R);
      Check (Boo (Is_Sorted (A)), Label & " Is_Sorted");
      Check (Same (A, R), Label & " matches reference");
      Check (Is_Permutation (A, O), Label & " permutation");
   end Expect_Sorted;

   --  Random test inputs: fixed default seed, printed at start; AA_SEED=<n> overrides it.
   function AA_Seed (Default : Natural) return Natural is
      V : constant String := Ada.Environment_Variables.Value ("AA_SEED", "");
      S : Natural := Default;
   begin
      if V /= "" then
         S := Natural (1 + abs (Long_Long_Integer'Value (V)) mod 2_147_483_646);
      end if;
      Ada.Text_IO.Put_Line ("AA_SEED =" & Natural'Image (S) & (if V = "" then " (default)" else " (from AA_SEED)"));
      return S;
   end AA_Seed;
   Seed : Natural := AA_Seed (42);

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
   Put_Line ("Bogosort (SPARK) tests");
   Put_Line ("======================");
   Put_Line ("Max_N =" & Max_N'Image & "  (keep n tiny — factorial!)");

   ---------------------------------------------------------------------
   Section ("1. Empty and singleton");
   ---------------------------------------------------------------------
   declare
      Empty : Element_Array (1 .. 0);
      One   : Element_Array := [1 => 42];
      Neg   : Element_Array := [1 => -7];
   begin
      Check (In_Bounds (Empty), "empty In_Bounds");
      Check (Boo (Is_Sorted (Empty)), "empty Is_Sorted");
      Run (Empty);
      Check (Boo (Is_Sorted (Empty)), "empty after Sort");
      Check (In_Bounds (One), "singleton In_Bounds");
      Check (Boo (Is_Sorted (One)), "singleton Is_Sorted");
      Run (One);
      Check (Int (One (One'First)) = 42, "singleton value preserved");
      Check (Boo (Is_Sorted (One)), "singleton after Sort");
      Run (Neg);
      Check (Int (Neg (Neg'First)) = -7, "negative singleton preserved");
      Check (Boo (Is_Sorted (Neg)), "negative singleton Is_Sorted");
   end;

   ---------------------------------------------------------------------
   Section ("2. Small patterns (n <= 8)");
   ---------------------------------------------------------------------
   Expect_Sorted ([3, 1, 2], "tiny 3");
   Expect_Sorted ([5, 4, 3, 2, 1], "reverse 5");
   Expect_Sorted ([1, 2, 3, 4, 5], "already sorted 5");
   Expect_Sorted ([2, 2, 2, 2], "all equal 4");
   Expect_Sorted ([9, 0, 5, 1, 8, 3], "mixed with zero");
   Expect_Sorted ([1, 0], "two swapped with zero");
   Expect_Sorted ([100, 100], "two equal");
   Expect_Sorted ([2, 1, 2, 1, 2, 1], "alternating");
   Expect_Sorted ([1, 2, 3, 5, 4], "almost sorted");
   Expect_Sorted ([0, 1, 0, 1, 0, 1, 0], "binary keys");
   Expect_Sorted ([0, 0, 0, 0], "all zeros");
   Expect_Sorted ([7], "singleton via Expect");
   Expect_Sorted ([6, 5, 4, 3, 2, 1], "reverse 6");
   Expect_Sorted ([7, 6, 5, 4, 3, 2, 1], "reverse 7");
   Expect_Sorted ([1, 3, 5, 7, 2, 4, 6], "odds then evens 7");
   Expect_Sorted ([8, 1, 2, 3, 4, 5, 6, 7], "rotated 8");
   Expect_Sorted ([1, 2], "two ascending");
   Expect_Sorted ([2, 1], "two descending");
   Expect_Sorted ([0, 0], "two zeros");
   Expect_Sorted ([3, 2, 1], "reverse 3");
   Expect_Sorted ([4, 1, 3, 2], "permute 4");
   Expect_Sorted ([9, 8, 7, 6, 5], "countdown 5");

   ---------------------------------------------------------------------
   Section ("3. Negatives and duplicates");
   ---------------------------------------------------------------------
   Expect_Sorted ([-3, -1, -2], "three negatives");
   Expect_Sorted ([-5, 0, 5, -2, 2], "negatives mixed");
   Expect_Sorted ([-1, -1, -1], "all equal negatives");
   Expect_Sorted ([5, 3, 5, 3, 5, 1, 1], "many dups");
   Expect_Sorted ([7, 7, 7, 1, 1, 9, 9], "runs of equals");
   Expect_Sorted ([-10, 10, -5, 5, 0], "symmetric around zero");
   Expect_Sorted ([4, 4, 4, 2, 2, 2, 4, 2], "two-value multiset");
   Expect_Sorted ([10, 1, 10, 1, 10, 1], "high-low alternating");
   Expect_Sorted ([-8, -3, -1, -2, -5, -4], "all negatives scrambled");
   Expect_Sorted ([-100, 100, -50], "sparse signed");
   Expect_Sorted ([Integer'First / 4, 0, Integer'Last / 4, -1, 1],
                  "large magnitude ints");

   ---------------------------------------------------------------------
   Section ("4. In_Bounds / Max_N shape");
   ---------------------------------------------------------------------
   declare
      Cap : constant Element_Array (1 .. Max_N) := [others => 0];
   begin
      Check (In_Bounds (Cap), "Max_N In_Bounds");
      --  All equal at Max_N — finishes in one Is_Sorted check (no n! walk).
      Expect_Sorted (Cap, "all-zero Max_N");
   end;
   declare
      Empty : Element_Array (1 .. 0);
   begin
      Check (In_Bounds (Empty), "empty still In_Bounds");
      Check (Nat (Empty'Length) = 0, "empty length 0");
   end;
   declare
      Ok : Element_Array (1 .. Max_N) := [others => 1];
   begin
      Run (Ok);
      Check (Boo (Is_Sorted (Ok)), "n = Max_N all equal sorts");
      Check (In_Bounds (Ok), "n = Max_N still In_Bounds");
   end;
   declare
      At_Cap_Sorted : Element_Array (1 .. Max_N);
   begin
      for I in At_Cap_Sorted'Range loop
         At_Cap_Sorted (I) := I;
      end loop;
      Run (At_Cap_Sorted);
      Check (Boo (Is_Sorted (At_Cap_Sorted)),
             "n = Max_N already-sorted stays sorted");
      Check (In_Bounds (At_Cap_Sorted), "n = Max_N sorted In_Bounds");
   end;
   --  Do NOT reverse-sort Max_N (=8) with distinct keys in CI — 8! steps.
   --  Reverse ≤ 7 is covered above.

   ---------------------------------------------------------------------
   Section ("5. Random arrays vs reference (tiny n only)");
   ---------------------------------------------------------------------
   Expect_Sorted (Random_Array (3, 0, 9), "random n=3 range 0..9");
   Expect_Sorted (Random_Array (4, -10, 20), "random n=4 signed");
   Expect_Sorted (Random_Array (5, 1, 5), "random n=5 range 1..5");
   Expect_Sorted (Random_Array (6, -3, 3), "random n=6 range -3..3");
   Expect_Sorted (Random_Array (7, 0, 0), "random n=7 all-zero span");
   Expect_Sorted (Random_Array (7, -5, 5), "random n=7 tiny");
   Expect_Sorted (Random_Array (5, 90, 100), "random n=5 high band");
   Expect_Sorted (Random_Array (6, -100, 100), "random n=6 wide");
   Expect_Sorted (Random_Array (8, 0, 3), "random n=8 few keys");
   Expect_Sorted (Random_Array (4, -2, 2), "random n=4 again");
   Expect_Sorted (Random_Array (8, 1, 1), "random n=8 all ones");
   Expect_Sorted (Random_Array (3, 0, 10), "random n=3");

   ---------------------------------------------------------------------
   Section ("6. Is_Sorted predicate");
   ---------------------------------------------------------------------
   Check (Boo (Is_Sorted ([1, 2, 3, 4])), "ascending true");
   Check (Boo (Is_Sorted ([1, 1, 2, 2])), "nondecreasing true");
   Check (not Boo (Is_Sorted ([1, 3, 2])), "inversion false");
   Check (not Boo (Is_Sorted ([5, 4, 3])), "reverse false");
   Check (Boo (Is_Sorted ([7])), "singleton true");
   Check (Boo (Is_Sorted ([0, 0, 0])), "zeros nondecreasing");
   Check (not Boo (Is_Sorted ([0, 2, 1])), "zero then inversion false");
   Check (Boo (Is_Sorted ([-3, -2, -1, 0])), "negatives ascending");
   Check (not Boo (Is_Sorted ([-1, -3])), "negatives inversion false");
   declare
      E : Element_Array (1 .. 0);
   begin
      Check (Boo (Is_Sorted (E)), "empty true");
   end;

   ---------------------------------------------------------------------
   Section ("7. Edge patterns");
   ---------------------------------------------------------------------
   Expect_Sorted ([1, 3, 5, 7, 2, 4, 6, 8], "odds then evens 8");
   Expect_Sorted ([8, 0, 8, 0, 8, 0, 8, 0], "sparse high/zero");
   declare
      A : Element_Array (1 .. 7);
   begin
      for I in A'Range loop
         A (I) := I;
      end loop;
      Expect_Sorted (A, "identity 1..7");
   end;
   declare
      A : Element_Array (1 .. 7);
   begin
      for I in A'Range loop
         A (I) := 8 - I;
      end loop;
      Expect_Sorted (A, "countdown 7..1");
   end;

   ---------------------------------------------------------------------
   Section ("8. Idempotence");
   ---------------------------------------------------------------------
   declare
      A : Element_Array := [9, 3, 7, 1, 5, 0, 4];
   begin
      Run (A);
      declare
         B : constant Element_Array := Copy_Of (A);
      begin
         Run (A);
         Check (Same (A, B), "second Sort is no-op on sorted");
         Check (Boo (Is_Sorted (A)), "idempotent still sorted");
      end;
   end;
   declare
      A : Element_Array := [1, 2, 3, 4, 5, 6];
   begin
      Run (A);
      declare
         B : constant Element_Array := Copy_Of (A);
      begin
         Run (A);
         Check (Same (A, B), "idempotent on already-sorted input");
      end;
   end;
   declare
      A : Element_Array := [4, 3, 2, 1];
   begin
      Run (A);
      declare
         B : constant Element_Array := Copy_Of (A);
      begin
         Run (A);
         Check (Same (A, B), "idempotent after reverse-4");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("9. Any origin");
   ---------------------------------------------------------------------
   --  The same input at origins 5, 200, 9 and ending at Positive'Last
   --  (empty: at Positive'Last) sorts to the origin-1 result.
   for Trial in 1 .. 40 loop
      declare
         Len  : constant Natural := Trial mod (6 + 1);
         Src  : constant Element_Array := Random_Array (Len, -5, 5);
         Want : Element_Array := Copy_Of (Src);
      begin
         Run (Want);
         for Which in 1 .. 4 loop
            declare
               F  : constant Positive :=
                 (case Which is
                    when 1 => 5, when 2 => 200, when 3 => 9,
                    when others =>
                      (if Len = 0 then Positive'Last
                       else Positive'Last - Len + 1));
               S  : Element_Array (F .. F + (Len - 1));
               Ok : Boolean := True;
            begin
               for K in 0 .. Len - 1 loop
                  S (F + K) := Src (Src'First + K);
               end loop;
               Run (S);
               for K in 0 .. Len - 1 loop
                  if S (F + K) /= Want (Want'First + K) then
                     Ok := False;
                  end if;
               end loop;
               Check (Ok and then Is_Sorted (S),
                      "origin" & F'Image & " n =" & Len'Image
                      & " sorts like origin 1");
            end;
         end loop;
      end;
   end loop;

   ---------------------------------------------------------------------
   Section ("10. Fixed seeds: exact shuffle counts (tests/shuffle_counts.py)");
   ---------------------------------------------------------------------
   declare
      procedure Exact
        (Src : Element_Array; Seed0 : Seed_Type; Want_N : Natural;
         Want_Seed : Seed_Type; Label : String)
      is
         A : Element_Array := Copy_Of (Src);
         W : Element_Array := Copy_Of (Src);
         S : Seed_Type := Seed0;
         R : Outcome;
         N : Natural;
      begin
         Sort (A, S, R, N);
         Reference_Sort (W);
         Check (R = Sorted, Label & " outcome Sorted");
         Check (Nat (N) = Want_N, Label & " exactly" & Want_N'Image
                & " shuffles (got" & N'Image & ")");
         Check (S = Want_Seed, Label & " final seed");
         Check (Same (A, W), Label & " matches reference");
      end Exact;
   begin
      Exact ([3, 1, 2], 1, 13, 3_037_600_243, "[3,1,2] seed 1");
      Exact ([5, 4, 3, 2, 1], 2024, 210, 3_423_104_208, "reverse 5 seed 2024");
      Exact ([2, 1, 2, 1, 2, 1], 7, 34, 1_301_041_465, "alternating seed 7");
      Exact ([7, 6, 5, 4, 3, 2, 1], 99, 1844, 1_744_471_195,
             "reverse 7 seed 99");
      Exact ([8, 1, 2, 3, 4, 5, 6, 7], 42, 96_536, 1_965_978_674,
             "rotated 8 seed 42");
   end;
   declare
      A : Element_Array := [1, 2, 3, 4];
      S : Seed_Type := 77;
      R : Outcome;
      N : Natural;
   begin
      Sort (A, S, R, N);
      Check (R = Sorted and then Nat (N) = 0 and then S = 77,
             "sorted input: 0 shuffles, seed untouched");
   end;

   ---------------------------------------------------------------------
   Section ("11. Gave_Up: budget spent, permutation kept");
   ---------------------------------------------------------------------
   declare
      procedure Give_Up
        (Src : Element_Array; Seed0 : Seed_Type; Budget : Shuffle_Count;
         Want : Element_Array; Want_Seed : Seed_Type; Label : String)
      is
         A : Element_Array := Copy_Of (Src);
         S : Seed_Type := Seed0;
         R : Outcome;
         N : Natural;
      begin
         Sort (A, S, R, N, Budget);
         Check (R = Gave_Up, Label & " outcome Gave_Up");
         Check (Nat (N) = Natural (Budget), Label & " all" & Budget'Image
                & " shuffles used");
         Check (not Is_Sorted (A), Label & " not sorted");
         Check (Is_Permutation (A, Src), Label & " permutation kept");
         Check (Same (A, Want), Label & " exact final array");
         Check (S = Want_Seed, Label & " final seed");
      end Give_Up;
   begin
      Give_Up ([2, 1], 5, 0, [2, 1], 5, "[2,1] budget 0");
      Give_Up ([7, 6, 5, 4, 3, 2, 1], 99, 10, [4, 2, 7, 5, 6, 1, 3],
               1_528_660_223, "reverse 7 budget 10");
      Give_Up ([4, 3, 2, 1], 3, 2, [4, 2, 3, 1], 3_714_889_393,
               "reverse 4 budget 2");
   end;
   declare
      A : Element_Array := [1, 2, 3];
      S : Seed_Type := 9;
      R : Outcome;
      N : Natural;
   begin
      Sort (A, S, R, N, 0);
      Check (R = Sorted and then Nat (N) = 0,
             "budget 0 on sorted input: Sorted, 0 shuffles");
   end;

   New_Line;
   Put_Line
     ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image
      & " FAIL");

   if Fail_Count /= 0 then
      raise Program_Error with "Bogosort SPARK tests failed";
   end if;
end Tests;
