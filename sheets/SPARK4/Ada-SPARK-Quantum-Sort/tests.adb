--  Standalone test suite for Quantum_Sort (SPARK port).
--  Preconditions replace exceptions; only valid call paths are exercised.
--  A'First is always 1; Max_N = 64. Sortedness is proved by SPARK;
--  multiset / permutation equality is checked here for all four Sort_*.

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Quantum_Sort; use Quantum_Sort;

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

   function Nat (X : Natural) return Natural is (X);
   function Int (X : Integer) return Integer is (X);
   function Boo (X : Boolean) return Boolean is (X);

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

   type Variant is
     (Comparison, Parallel_Network, Frequency, Space_Bounded);

   function Variant_Name (V : Variant) return String is
   begin
      case V is
         when Comparison       => return "Comparison";
         when Parallel_Network => return "Parallel_Network";
         when Frequency        => return "Frequency";
         when Space_Bounded    => return "Space_Bounded";
      end case;
   end Variant_Name;

   procedure Sort_By (V : Variant; A : in out Element_Array) is
   begin
      case V is
         when Comparison       => Sort_Comparison (A);
         when Parallel_Network => Sort_Parallel_Network (A);
         when Frequency        => Sort_Frequency (A);
         when Space_Bounded    => Sort_Space_Bounded (A);
      end case;
   end Sort_By;

   --  Run all four variants: Is_Sorted, match reference, permutation,
   --  and cross-variant agreement on the sorted multiset.
   procedure Expect_Sorted (Src : Element_Array; Label : String) is
      O  : constant Element_Array := Copy_Of (Src);
      R  : Element_Array := Copy_Of (Src);
      A1 : Element_Array := Copy_Of (Src);
      A2 : Element_Array := Copy_Of (Src);
      A3 : Element_Array := Copy_Of (Src);
      A4 : Element_Array := Copy_Of (Src);
   begin
      Reference_Sort (R);
      Sort_Comparison (A1);
      Sort_Parallel_Network (A2);
      Sort_Frequency (A3);
      Sort_Space_Bounded (A4);

      Check (Boo (Is_Sorted (A1)), Label & " Comparison Is_Sorted");
      Check (Same (A1, R), Label & " Comparison matches reference");
      Check (Is_Permutation (A1, O), Label & " Comparison permutation");

      Check (Boo (Is_Sorted (A2)), Label & " Parallel Is_Sorted");
      Check (Same (A2, R), Label & " Parallel matches reference");
      Check (Is_Permutation (A2, O), Label & " Parallel permutation");

      Check (Boo (Is_Sorted (A3)), Label & " Frequency Is_Sorted");
      Check (Same (A3, R), Label & " Frequency matches reference");
      Check (Is_Permutation (A3, O), Label & " Frequency permutation");

      Check (Boo (Is_Sorted (A4)), Label & " Space_Bounded Is_Sorted");
      Check (Same (A4, R), Label & " Space_Bounded matches reference");
      Check (Is_Permutation (A4, O), Label & " Space_Bounded permutation");

      Check (Same (A1, A2) and then Same (A2, A3) and then Same (A3, A4),
             Label & " all variants agree");
   end Expect_Sorted;

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
   Put_Line ("Quantum_Sort (SPARK) tests");
   Put_Line ("==========================");

   ---------------------------------------------------------------------
   Section ("1. Empty and singleton");
   ---------------------------------------------------------------------
   declare
      Empty : Element_Array (1 .. 0);
      One   : constant Element_Array := [1 => 42];
      Neg   : constant Element_Array := [1 => -7];
   begin
      Check (In_Bounds (Empty), "empty In_Bounds");
      Check (Boo (Is_Sorted (Empty)), "empty Is_Sorted");
      for V in Variant loop
         Sort_By (V, Empty);
         Check (Boo (Is_Sorted (Empty)),
                "empty after " & Variant_Name (V));
      end loop;
      Check (In_Bounds (One), "singleton In_Bounds");
      Check (Boo (Is_Sorted (One)), "singleton Is_Sorted");
      for V in Variant loop
         declare
            A : Element_Array := One;
         begin
            Sort_By (V, A);
            Check (Int (A (A'First)) = 42,
                   "singleton value " & Variant_Name (V));
            Check (Boo (Is_Sorted (A)),
                   "singleton sorted " & Variant_Name (V));
         end;
      end loop;
      for V in Variant loop
         declare
            A : Element_Array := Neg;
         begin
            Sort_By (V, A);
            Check (Int (A (A'First)) = -7,
                   "neg singleton " & Variant_Name (V));
         end;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("2. Small patterns (all variants)");
   ---------------------------------------------------------------------
   Expect_Sorted ([3, 1, 2], "tiny 3");
   Expect_Sorted ([5, 4, 3, 2, 1], "reverse 5");
   Expect_Sorted ([1, 2, 3, 4, 5], "already sorted");
   Expect_Sorted ([2, 2, 2, 2], "all equal");
   Expect_Sorted ([9, 0, 5, 1, 8, 3], "mixed with zero");
   Expect_Sorted
     ([62, 83, 18, 53, 7, 17, 95, 78, 58, 70, 25, 28], "wikipedia 12");
   Expect_Sorted ([1, 0], "two swapped with zero");
   Expect_Sorted ([100, 100], "two equal");
   Expect_Sorted ([2, 1, 2, 1, 2, 1], "alternating");
   Expect_Sorted ([1, 2, 3, 5, 4], "almost sorted");
   Expect_Sorted ([9, 8, 7, 6, 5, 4, 3, 2, 1, 0], "reverse 10 with zero");
   Expect_Sorted ([0, 1, 0, 1, 0, 1, 0], "binary keys");
   Expect_Sorted ([0, 0, 0, 0], "all zeros");
   Expect_Sorted ([7], "singleton via Expect");

   ---------------------------------------------------------------------
   Section ("3. Negatives and duplicates");
   ---------------------------------------------------------------------
   Expect_Sorted ([-3, -1, -2], "three negatives");
   Expect_Sorted ([-5, 0, 5, -2, 2], "negatives mixed");
   Expect_Sorted ([-1, -1, -1], "all equal negatives");
   Expect_Sorted ([5, 3, 5, 3, 5, 1, 1], "many dups");
   Expect_Sorted ([7, 7, 7, 1, 1, 9, 9, 9, 9], "runs of equals");
   Expect_Sorted ([-10, 10, -5, 5, 0], "symmetric around zero");
   Expect_Sorted ([4, 4, 4, 2, 2, 2, 4, 2], "two-value multiset");
   Expect_Sorted ([10, 1, 10, 1, 10, 1, 10], "high-low alternating");

   ---------------------------------------------------------------------
   Section ("4. Tagged multisets (permutation; stability where claimed)");
   ---------------------------------------------------------------------
   declare
      --  Tagged keys: Selection/Shell may reorder equal keys; Insertion
      --  and Cocktail (strict >) keep tag order. Check permutation for
      --  all; check stability only for Comparison and Space_Bounded.
      Src : constant Element_Array := [2001, 1002, 2003, 1004, 2005];
      O   : constant Element_Array := Copy_Of (Src);
   begin
      for V in Variant loop
         declare
            A : Element_Array := Copy_Of (Src);
         begin
            Sort_By (V, A);
            Check (Boo (Is_Sorted (A)),
                   "tagged Is_Sorted " & Variant_Name (V));
            Check (Is_Permutation (A, O),
                   "tagged permutation " & Variant_Name (V));
         end;
      end loop;
      declare
         A : Element_Array := Copy_Of (Src);
         R : Element_Array := Copy_Of (Src);
      begin
         Sort_Comparison (A);
         Reference_Sort (R);
         Check (Same (A, R), "Comparison tagged matches reference");
         Check (Int (A (1)) = 1002 and then Int (A (2)) = 1004,
                "Comparison key-1 tags stable");
         Check (Int (A (3)) = 2001
                and then Int (A (4)) = 2003
                and then Int (A (5)) = 2005,
                "Comparison key-2 tags stable");
      end;
      declare
         A : Element_Array := Copy_Of (Src);
         R : Element_Array := Copy_Of (Src);
      begin
         Sort_Space_Bounded (A);
         Reference_Sort (R);
         Check (Same (A, R), "Space_Bounded tagged matches reference");
         Check (Int (A (1)) = 1002 and then Int (A (2)) = 1004,
                "Space_Bounded key-1 tags stable");
         Check (Int (A (3)) = 2001
                and then Int (A (4)) = 2003
                and then Int (A (5)) = 2005,
                "Space_Bounded key-2 tags stable");
      end;
   end;
   Expect_Sorted ([5, 3, 5, 3, 5, 1, 1], "dups again");
   Expect_Sorted ([1, 1, 1, 1, 1, 1, 1, 1], "eight ones");

   ---------------------------------------------------------------------
   Section ("5. In_Bounds / Max_N shape");
   ---------------------------------------------------------------------
   declare
      Cap : Element_Array (1 .. Max_N) := [others => 0];
   begin
      Check (In_Bounds (Cap), "Max_N In_Bounds");
      for I in Cap'Range loop
         Cap (I) := Integer (Max_N + 1 - I);
      end loop;
      Expect_Sorted (Cap, "reverse Max_N");
   end;
   declare
      Empty : Element_Array (1 .. 0);
   begin
      Check (In_Bounds (Empty), "empty still In_Bounds");
      Check (Nat (Empty'Length) = 0, "empty length 0");
   end;

   ---------------------------------------------------------------------
   Section ("6. Random arrays vs reference");
   ---------------------------------------------------------------------
   Expect_Sorted (Random_Array (20, 0, 9), "random n=20 range 0..9");
   Expect_Sorted (Random_Array (50, -10, 20), "random n=50 range -10..20");
   Expect_Sorted (Random_Array (64, 1, 5), "random n=64 range 1..5");
   Expect_Sorted (Random_Array (32, -50, 50), "random n=32 signed");
   Expect_Sorted (Random_Array (16, 0, 0), "random all-zero span");
   Expect_Sorted (Random_Array (40, 1, 1), "random all-ones");
   Expect_Sorted (Random_Array (25, -100, 100), "random wide signed");
   Expect_Sorted (Random_Array (7, -5, 5), "random n=7 tiny");
   Expect_Sorted (Random_Array (12, -1000, 1000), "random n=12 wide");
   Expect_Sorted (Random_Array (58, -20, 20), "random n=58 near Ciura 57");
   Expect_Sorted (Random_Array (5, 0, 9), "n=5 engages gap 4");
   Expect_Sorted (Random_Array (11, -5, 5), "n=11 engages gap 10");
   Expect_Sorted (Random_Array (24, -9, 9), "n=24 engages gap 23");

   ---------------------------------------------------------------------
   Section ("7. Is_Sorted predicate");
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
   Check (Boo (Is_Sorted ([1, 2])), "pair ascending true");
   Check (not Boo (Is_Sorted ([2, 1])), "pair descending false");
   declare
      E : Element_Array (1 .. 0);
   begin
      Check (Boo (Is_Sorted (E)), "empty true");
   end;

   ---------------------------------------------------------------------
   Section ("8. Edge patterns, turtle, lengths");
   ---------------------------------------------------------------------
   Expect_Sorted ([1, 2], "two ascending");
   Expect_Sorted ([2, 1], "two descending");
   Expect_Sorted ([0, 0], "two zeros");
   Expect_Sorted ([-100, 100, -50], "sparse signed");
   Expect_Sorted ([15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1],
                  "reverse 15");
   Expect_Sorted ([1, 3, 5, 7, 9, 2, 4, 6, 8, 10], "odds then evens");
   Expect_Sorted ([2, 3, 4, 5, 1], "cocktail turtle");
   Expect_Sorted ([50, 40, 30, 20, 10, 1, 2, 3], "turtles at end");
   Expect_Sorted ([9, 8, 7, 6, 5, 4, 3, 2, 1, -100], "deep turtle last");
   Expect_Sorted ([8, 0, 8, 0, 8, 0, 8, 0], "sparse high/zero");
   Expect_Sorted ([1, 10, 2, 20, 3, 30, 4, 40], "two interleaved runs");
   Expect_Sorted ([100, 1, 99, 2, 98, 3, 97, 4, 96, 5], "sawtooth");
   Expect_Sorted ([1, 2, 4, 8, 16, 32, 64, 128, 256, 3],
                  "powers then disrupt");
   Expect_Sorted ([5, 4, 3, 2, 1, 0, -1, -2], "strict reverse signed");
   declare
      A : Element_Array (1 .. 10);
   begin
      for I in A'Range loop
         A (I) := I;
      end loop;
      Expect_Sorted (A, "identity 1..10");
   end;
   declare
      A : Element_Array (1 .. 10);
   begin
      for I in A'Range loop
         A (I) := 11 - I;
      end loop;
      Expect_Sorted (A, "countdown 10..1");
   end;
   declare
      A : Element_Array (1 .. 64);
   begin
      for I in A'Range loop
         A (I) := I;
      end loop;
      Expect_Sorted (A, "already sorted n=64");
   end;
   declare
      A : Element_Array (1 .. 32);
   begin
      for I in A'Range loop
         A (I) := 33 - I;
      end loop;
      Expect_Sorted (A, "reverse n=32");
   end;
   declare
      A : Element_Array (1 .. 17);
   begin
      for I in A'Range loop
         A (I) := 18 - I;
      end loop;
      Expect_Sorted (A, "odd length reverse 17");
   end;
   declare
      A : Element_Array (1 .. 50);
   begin
      for I in A'Range loop
         A (I) := I;
      end loop;
      A (25) := 1;
      A (1) := 25;
      Expect_Sorted (A, "nearly sorted n=50 one swap");
   end;

   ---------------------------------------------------------------------
   Section ("9. Idempotence (all variants)");
   ---------------------------------------------------------------------
   declare
      Src : constant Element_Array := [9, 3, 7, 1, 5, 0, 4, -2];
   begin
      for V in Variant loop
         declare
            A : Element_Array := Copy_Of (Src);
         begin
            Sort_By (V, A);
            declare
               B : constant Element_Array := Copy_Of (A);
            begin
               Sort_By (V, A);
               Check (Same (A, B),
                      "idempotent " & Variant_Name (V));
               Check (Boo (Is_Sorted (A)),
                      "idempotent still sorted " & Variant_Name (V));
            end;
         end;
      end loop;
   end;
   declare
      Src : constant Element_Array := [1, 2, 3, 4, 5, 6];
   begin
      for V in Variant loop
         declare
            A : Element_Array := Copy_Of (Src);
         begin
            Sort_By (V, A);
            declare
               B : constant Element_Array := Copy_Of (A);
            begin
               Sort_By (V, A);
               Check (Same (A, B),
                      "idempotent sorted " & Variant_Name (V));
            end;
         end;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("10. Large magnitude and adversarial");
   ---------------------------------------------------------------------
   Expect_Sorted ([Integer'First / 4, 0, Integer'Last / 4, -1, 1],
                  "large magnitude ints");
   Expect_Sorted ([Integer'First, Integer'Last, 0], "extreme pair with zero");
   Expect_Sorted ([Integer'Last, Integer'First], "Last then First");
   Expect_Sorted ([3, 3, 2, 2, 1, 1], "dup reverse pairs again");
   Expect_Sorted ([42, -7, 13, 0, 99, -42, 13, 5], "non-SPARK consistency set");
   declare
      A : Element_Array (1 .. 63);
   begin
      for I in A'Range loop
         A (I) := (I * 17) rem 63;
      end loop;
      Expect_Sorted (A, "linear congruential n=63");
   end;
   declare
      A : Element_Array (1 .. 64);
   begin
      for I in A'Range loop
         A (I) := 65 - I;
      end loop;
      Expect_Sorted (A, "reverse n=64");
   end;
   Expect_Sorted ([0], "zero singleton via Expect");
   Expect_Sorted ([-42], "neg singleton via Expect");

   New_Line;
   Put_Line
     ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image
      & " FAIL");

   if Fail_Count /= 0 then
      raise Program_Error with "Quantum_Sort tests failed";
   end if;
end Tests;
