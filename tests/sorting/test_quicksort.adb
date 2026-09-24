--  Test suite for Quicksort (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Quicksort; use Quicksort;

procedure Test_Quicksort is

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

   --  Insertion-sort reference (ascending).
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

   function Copy_Of (A : Element_Array) return Element_Array is
   begin
      return Element_Array'(A);
   end Copy_Of;

   function Sort_Raises (A : Element_Array) return Boolean is
      T : Element_Array := A;
   begin
      Sort (T);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Sort_Raises;

   procedure Expect_Sorted (Src : Element_Array; Label : String) is
      A : Element_Array := Copy_Of (Src);
      R : Element_Array := Copy_Of (Src);
   begin
      Sort (A);
      Reference_Sort (R);
      Check (Is_Sorted (A), Label & " Is_Sorted");
      Check (Same (A, R), Label & " matches reference");
   end Expect_Sorted;

   --  Deterministic LCG.
   Seed : Natural := 1_234_567;

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

   function Random_Array (Len : Natural; Lo, Hi : Integer) return Element_Array
   is
      Span_LL : constant Long_Long_Integer :=
        Long_Long_Integer (Hi) - Long_Long_Integer (Lo) + 1;
      Span    : constant Positive := Positive (Span_LL);
      A       : Element_Array (1 .. Len);
   begin
      for I in A'Range loop
         A (I) := Lo + Integer (Next_Mod (Span));
      end loop;
      return A;
   end Random_Array;

   function Sawtooth (Len : Natural; Period : Positive) return Element_Array is
      A : Element_Array (1 .. Len);
   begin
      for I in A'Range loop
         A (I) := (I - 1) rem Period;
      end loop;
      return A;
   end Sawtooth;

   function Organ_Pipe (Len : Natural) return Element_Array is
      A   : Element_Array (1 .. Len);
      Mid : constant Natural := (Len + 1) / 2;
   begin
      for I in 1 .. Mid loop
         A (I) := I;
      end loop;
      for I in Mid + 1 .. Len loop
         A (I) := Len - I + 1;
      end loop;
      return A;
   end Organ_Pipe;

begin
   ---------------------------------------------------------------------
   Section ("1. Empty and singleton");
   ---------------------------------------------------------------------
   declare
      E : Element_Array (1 .. 0);
      S : Element_Array (1 .. 1) := [42];
      Z : Element_Array (0 .. 0) := [0 => -7];
   begin
      Check (Is_Sorted (E), "empty Is_Sorted");
      Sort (E);
      Check (Is_Sorted (E), "empty Sort no-op");
      Check (Is_Sorted (S), "singleton Is_Sorted");
      Sort (S);
      Check (S (1) = 42, "singleton Sort preserves");
      Sort (Z);
      Check (Z (0) = -7, "0-based singleton Sort preserves");
   end;

   ---------------------------------------------------------------------
   Section ("2. Already sorted / reverse / duplicates");
   ---------------------------------------------------------------------
   Expect_Sorted ([1, 2, 3, 4, 5], "already sorted");
   Expect_Sorted ([5, 4, 3, 2, 1], "fully reversed");
   Expect_Sorted ([3, 1, 4, 1, 5, 9, 2, 6], "pi digits");
   Expect_Sorted ([7, 7, 7, 7], "all equal");
   Expect_Sorted ([2, 1, 2, 1, 2], "alternating duplicates");
   Expect_Sorted ([0, -1, 0, -1], "zeros and negatives");
   Expect_Sorted ([5, 5, 5, 1, 5, 5], "mostly equal");

   ---------------------------------------------------------------------
   Section ("3. Classic small examples");
   ---------------------------------------------------------------------
   declare
      A : Element_Array := [64, 25, 12, 22, 11];
   begin
      Sort (A);
      Check (Same (A, [11, 12, 22, 25, 64]), "worked example sorts to known");
      Check (Is_Sorted (A), "worked example Is_Sorted");
   end;
   Expect_Sorted ([1, 2], "two ascending");
   Expect_Sorted ([2, 1], "two descending");
   Expect_Sorted ([1, 1], "two equal");
   Expect_Sorted ([3, 1, 2], "perm 3,1,2");
   Expect_Sorted ([2, 3, 1], "perm 2,3,1");
   Expect_Sorted ([1, 3, 2], "perm 1,3,2");

   ---------------------------------------------------------------------
   Section ("4. Negatives and extreme Integers");
   ---------------------------------------------------------------------
   Expect_Sorted ([-5, -1, -3, -2, -4], "all negatives");
   Expect_Sorted ([Integer'First, 0, Integer'Last], "extremes trio");
   Expect_Sorted
     ([Integer'Last, Integer'First, Integer'First + 1, -1],
      "extremes quartet");
   Expect_Sorted ([-100, 50, -50, 100, 0], "mixed signs");

   ---------------------------------------------------------------------
   Section ("5. Non-1-based bounds");
   ---------------------------------------------------------------------
   declare
      A : Element_Array (0 .. 4) := [0 => 9, 1 => 3, 2 => 7, 3 => 1, 4 => 5];
      R : Element_Array (0 .. 4);
   begin
      R := A;
      Sort (A);
      Reference_Sort (R);
      Check (Is_Sorted (A), "0-based Is_Sorted");
      Check (Same (A, R), "0-based matches reference");
   end;
   declare
      A : Element_Array (10 .. 14) :=
        [10 => 4, 11 => 2, 12 => 8, 13 => 6, 14 => 0];
      R : Element_Array (10 .. 14);
   begin
      R := A;
      Sort (A);
      Reference_Sort (R);
      Check (A (10) = 0 and then A (14) = 8, "10-based first/last");
      Check (Same (A, R), "10-based matches reference");
   end;
   declare
      A : Element_Array (5 .. 20) :=
        [5 => 16, 6 => 15, 7 => 14, 8 => 13, 9 => 12, 10 => 11,
         11 => 10, 12 => 9, 13 => 8, 14 => 7, 15 => 6, 16 => 5,
         17 => 4, 18 => 3, 19 => 2, 20 => 1];
   begin
      Sort (A);
      Check (Is_Sorted (A), "5-based reverse Is_Sorted");
      Check (A (5) = 1 and then A (20) = 16, "5-based first/last after sort");
   end;

   ---------------------------------------------------------------------
   Section ("6. Is_Sorted predicates");
   ---------------------------------------------------------------------
   Check (Is_Sorted ([1, 2, 2, 3]), "nondecreasing true");
   Check (not Is_Sorted ([1, 3, 2]), "unsorted ascending false");
   Check (Is_Sorted ([Integer'First, Integer'First]), "equal extremes sorted");
   Check (not Is_Sorted ([0, -1]), "descending pair not sorted");
   Check (Is_Sorted ([1]), "singleton predicate");
   declare
      E : Element_Array (1 .. 0);
   begin
      Check (Is_Sorted (E), "empty predicate");
   end;

   ---------------------------------------------------------------------
   Section ("7. Small and mid sizes");
   ---------------------------------------------------------------------
   Expect_Sorted (Random_Array (1, -10, 10), "n=1");
   Expect_Sorted (Random_Array (8, -100, 100), "n=8");
   Expect_Sorted (Random_Array (15, -100, 100), "n=15");
   Expect_Sorted (Random_Array (16, -100, 100), "n=16");
   Expect_Sorted ([16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1],
                  "n=16 reverse");

   ---------------------------------------------------------------------
   Section ("8. Larger random vs reference");
   ---------------------------------------------------------------------
   Expect_Sorted (Random_Array (17, -100, 100), "n=17");
   Expect_Sorted (Random_Array (32, -50, 50), "random n=32");
   Expect_Sorted (Random_Array (64, -20, 20), "random n=64");
   Expect_Sorted (Random_Array (100, 0, 10), "random n=100 many dups");
   Expect_Sorted (Random_Array (200, -500, 500), "random n=200");
   Expect_Sorted (Random_Array (512, -1000, 1000), "random n=512");
   Expect_Sorted (Random_Array (1000, -100, 100), "random n=1000");
   Expect_Sorted (Random_Array (50, 1, 1), "random all identical n=50");

   ---------------------------------------------------------------------
   Section ("9. Adversarial patterns (pivot stress)");
   ---------------------------------------------------------------------
   declare
      A : Element_Array (1 .. 64);
   begin
      for I in A'Range loop
         A (I) := I;
      end loop;
      Expect_Sorted (A, "sorted n=64");
   end;
   declare
      A : Element_Array (1 .. 128);
   begin
      for I in A'Range loop
         A (I) := I;
      end loop;
      Expect_Sorted (A, "sorted n=128");
   end;
   declare
      A : Element_Array (1 .. 256);
   begin
      for I in A'Range loop
         A (I) := 257 - I;
      end loop;
      Expect_Sorted (A, "reverse n=256");
   end;
   declare
      A : constant Element_Array (1 .. 200) := [others => 42];
   begin
      Expect_Sorted (A, "all equal n=200");
   end;
   Expect_Sorted (Sawtooth (100, 7), "sawtooth period 7");
   Expect_Sorted (Sawtooth (200, 3), "sawtooth period 3");
   Expect_Sorted (Sawtooth (64, 16), "sawtooth period 16");
   Expect_Sorted (Organ_Pipe (99), "organ pipe n=99");
   Expect_Sorted (Organ_Pipe (128), "organ pipe n=128");
   Expect_Sorted
     ([1, 3, 5, 7, 9, 11, 13, 15, 14, 12, 10, 8, 6, 4, 2, 0,
       1, 3, 5, 7, 9, 11, 13, 15, 14, 12, 10, 8, 6, 4, 2, 0],
      "two organ half-waves");

   ---------------------------------------------------------------------
   Section ("10. Capacity / Invalid_Argument");
   ---------------------------------------------------------------------
   declare
      Big : constant Element_Array (1 .. Max_N + 1) := [others => 0];
   begin
      Check (Sort_Raises (Big), "oversize Sort raises Invalid_Argument");
   end;
   declare
      Ok : Element_Array (1 .. 3) := [3, 1, 2];
   begin
      Sort (Ok);
      Check (Same (Ok, [1, 2, 3]), "under Max_N still sorts");
   end;
   declare
      Tiny : Element_Array (1 .. 32);
   begin
      for I in Tiny'Range loop
         Tiny (I) := Tiny'Last - I + Tiny'First;
      end loop;
      Sort (Tiny);
      Check (Is_Sorted (Tiny), "n=32 reverse under Max_N");
      Check (Tiny (Tiny'First) <= Tiny (Tiny'Last), "n=32 endpoints ordered");
      Check (not Sort_Raises (Tiny), "n=32 does not raise Invalid_Argument");
   end;

   ---------------------------------------------------------------------
   Section ("11. Idempotence");
   ---------------------------------------------------------------------
   declare
      A : Element_Array := [9, 4, 1, 8, 2, 7, 3, 6, 5, 0, -1, 11];
      B : Element_Array (A'Range);
   begin
      Sort (A);
      B := A;
      Sort (A);
      Check (Same (A, B), "Sort twice is idempotent");
      Check (Is_Sorted (A), "idempotent result still sorted");
   end;
   declare
      A : Element_Array := Random_Array (300, -999, 999);
      B : Element_Array (A'Range);
   begin
      Sort (A);
      B := A;
      Sort (A);
      Check (Same (A, B), "idempotent on random n=300");
   end;

   ---------------------------------------------------------------------
   Section ("12. Nearly sorted / single inversion");
   ---------------------------------------------------------------------
   Expect_Sorted ([1, 2, 3, 5, 4], "single swap near end");
   Expect_Sorted ([2, 1, 3, 4, 5], "single swap near start");
   Expect_Sorted ([1, 2, 2, 2, 1], "dups with inversion");
   Expect_Sorted ([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 11], "near-sorted n=12");
   Expect_Sorted
     ([20, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19],
      "rotated nearly sorted");

   ---------------------------------------------------------------------
   Section ("13. More random vs reference");
   ---------------------------------------------------------------------
   Expect_Sorted (Random_Array (2, -100, 100), "random n=2");
   Expect_Sorted (Random_Array (3, -100, 100), "random n=3");
   Expect_Sorted (Random_Array (5, -100, 100), "random n=5");
   Expect_Sorted (Random_Array (7, -1000, 1000), "random n=7");
   Expect_Sorted (Random_Array (24, -200, 200), "random n=24");
   Expect_Sorted (Random_Array (48, -200, 200), "random n=48");
   Expect_Sorted (Random_Array (96, -50, 50), "random n=96");
   Expect_Sorted (Random_Array (250, -10, 10), "random n=250 heavy dups");
   Expect_Sorted (Random_Array (400, -1_000_000_000, 1_000_000_000),
                  "random n=400 wide range");

   ---------------------------------------------------------------------
   Section ("14. Larger reverse / random");
   ---------------------------------------------------------------------
   declare
      A : Element_Array (1 .. 1024);
   begin
      for I in A'Range loop
         A (I) := 1025 - I;
      end loop;
      Sort (A);
      Check (Is_Sorted (A), "reverse n=1024 Is_Sorted");
      Check (A (1) = 1 and then A (1024) = 1024, "reverse n=1024 endpoints");
   end;
   declare
      A : Element_Array (1 .. 2048);
   begin
      for I in A'Range loop
         A (I) := Integer (Next_Mod (10_000)) - 5_000;
      end loop;
      declare
         R : Element_Array := Copy_Of (A);
      begin
         Sort (A);
         Reference_Sort (R);
         Check (Is_Sorted (A), "random n=2048 Is_Sorted");
         Check (Same (A, R), "random n=2048 matches reference");
      end;
   end;

   New_Line;
   Put_Line
     ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image
      & " FAIL");

   if Fail_Count /= 0 then
      raise Program_Error with "Test_Quicksort failed";
   end if;
end Test_Quicksort;
