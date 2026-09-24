--  Standalone test suite for Pigeonhole_Sort (SPARK port).
--  Preconditions replace exceptions; only valid call paths are exercised.
--  A'First is always 1; Max_N = 64; key span ≤ Max_Range = 256.
--  Sortedness is proved by SPARK; multiset / permutation equality is
--  checked here.

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Pigeonhole_Sort; use Pigeonhole_Sort;

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

   procedure Expect_Sorted (Src : Element_Array; Label : String) is
      A : Element_Array := Copy_Of (Src);
      R : Element_Array := Copy_Of (Src);
      O : constant Element_Array := Copy_Of (Src);
   begin
      Check (In_Bounds (A), Label & " In_Bounds");
      Check (Keys_In_Range (A), Label & " Keys_In_Range");
      Sort (A);
      Reference_Sort (R);
      Check (Boo (Is_Sorted (A)), Label & " Is_Sorted");
      Check (Same (A, R), Label & " matches reference");
      Check (Is_Permutation (A, O), Label & " permutation");
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

   --  Random array with Lo..Hi span ≤ Max_Range (caller responsibility).
   function Random_Array
     (Len : Natural; Lo, Hi : Integer) return Element_Array
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

begin
   Put_Line ("Pigeonhole_Sort (SPARK) tests");
   Put_Line ("=============================");

   ---------------------------------------------------------------------
   Section ("1. Empty and singleton");
   ---------------------------------------------------------------------
   declare
      Empty : Element_Array (1 .. 0);
      One   : Element_Array := [1 => 42];
      Neg   : Element_Array := [1 => -7];
   begin
      Check (In_Bounds (Empty), "empty In_Bounds");
      Check (Keys_In_Range (Empty), "empty Keys_In_Range");
      Check (Boo (Is_Sorted (Empty)), "empty Is_Sorted");
      Sort (Empty);
      Check (Boo (Is_Sorted (Empty)), "empty after Sort");
      Check (In_Bounds (One), "singleton In_Bounds");
      Check (Keys_In_Range (One), "singleton Keys_In_Range");
      Check (Boo (Is_Sorted (One)), "singleton Is_Sorted");
      Sort (One);
      Check (Int (One (One'First)) = 42, "singleton value preserved");
      Check (Boo (Is_Sorted (One)), "singleton after Sort");
      Sort (Neg);
      Check (Int (Neg (Neg'First)) = -7, "negative singleton preserved");
      Check (Boo (Is_Sorted (Neg)), "negative singleton Is_Sorted");
   end;
   Expect_Sorted ([0], "zero singleton via Expect");
   Expect_Sorted ([-7], "negative singleton via Expect");

   ---------------------------------------------------------------------
   Section ("2. Small dense ranges");
   ---------------------------------------------------------------------
   Expect_Sorted ([3, 1, 2], "tiny 3");
   Expect_Sorted ([5, 4, 3, 2, 1], "reverse 5");
   Expect_Sorted ([1, 2, 3, 4, 5], "already sorted");
   Expect_Sorted ([2, 2, 2, 2], "all equal");
   Expect_Sorted ([9, 0, 5, 1, 8, 3], "mixed small");
   Expect_Sorted ([1, 3, 2, 3, 1, 2], "dups interleaved");
   Expect_Sorted ([0, 0, 1, 1, 0], "binary keys");

   ---------------------------------------------------------------------
   Section ("3. Negatives and positives (span ≤ Max_Range)");
   ---------------------------------------------------------------------
   Expect_Sorted ([-3, -1, -2], "all negative");
   Expect_Sorted ([-5, 0, 5, -2, 3], "neg+pos");
   Expect_Sorted ([-10, -10, 10, 0, -1], "neg+pos dups");
   Expect_Sorted ([-100, 50, -50, 0, 100, -1], "wider signed");
   Expect_Sorted ([Integer'First + 10, Integer'First + 5,
                   Integer'First + 7], "near Integer'First");
   Expect_Sorted ([Integer'Last - 3, Integer'Last, Integer'Last - 1],
                  "near Integer'Last");
   Expect_Sorted ([-128, 127, 0, -1, 1], "byte-ish signed");

   ---------------------------------------------------------------------
   Section ("4. Stability / multiset vs reference");
   ---------------------------------------------------------------------
   Expect_Sorted ([5, 3, 5, 3, 5, 1, 1], "stable-ish dups");
   Expect_Sorted ([7, 7, 7, 7, 7, 7, 7], "seven equal");
   Expect_Sorted ([4, 2, 4, 2, 4, 2, 4, 2], "alternating pair");

   ---------------------------------------------------------------------
   Section ("5. Max_N length and Max_Range span");
   ---------------------------------------------------------------------
   declare
      Full : Element_Array (1 .. Max_N);
   begin
      for I in Full'Range loop
         Full (I) := Max_N - I;
      end loop;
      Expect_Sorted (Full, "Max_N reverse 0..63");
   end;
   declare
      --  Span = 256 = Max_Range exactly (keys 0 .. 255).
      Edge : Element_Array (1 .. 16);
   begin
      for I in Edge'Range loop
         Edge (I) := Integer ((I - 1) * 17) rem 256;
      end loop;
      Check (Keys_In_Range (Edge), "span=256 Keys_In_Range");
      Expect_Sorted (Edge, "exact Max_Range span 0..255");
   end;
   declare
      Band : Element_Array (1 .. 32);
   begin
      for I in Band'Range loop
         Band (I) := 1000 + Integer ((I * 7) rem 200);
      end loop;
      Expect_Sorted (Band, "offset band 1000..1199");
   end;

   ---------------------------------------------------------------------
   Section ("6. Random compact ranges");
   ---------------------------------------------------------------------
   Expect_Sorted (Random_Array (20, 0, 50), "random 20 in 0..50");
   Expect_Sorted (Random_Array (40, -20, 20), "random 40 in -20..20");
   Expect_Sorted (Random_Array (Max_N, 0, 255), "random Max_N in 0..255");
   Expect_Sorted (Random_Array (30, -100, 100), "random 30 in -100..100");
   Expect_Sorted
     (Random_Array (25, Integer'First, Integer'First + 50),
      "random near First");
   Expect_Sorted
     (Random_Array (25, Integer'Last - 50, Integer'Last),
      "random near Last");

   ---------------------------------------------------------------------
   Section ("7. Contract helpers");
   ---------------------------------------------------------------------
   declare
      Ok    : constant Element_Array := [1, 2, 3];
      Bad   : constant Element_Array := [3, 1, 2];
      Wide  : constant Element_Array := [0, Max_Range];  -- span = Max_Range+1
      Empty : Element_Array (1 .. 0);
      Full  : constant Element_Array (1 .. Max_N) := [others => 0];
   begin
      Check (Boo (Is_Sorted (Ok)), "Is_Sorted true on sorted");
      Check (not Boo (Is_Sorted (Bad)), "Is_Sorted false on unsorted");
      Check (In_Bounds (Ok), "In_Bounds small");
      Check (In_Bounds (Empty), "In_Bounds empty");
      Check (In_Bounds (Full), "In_Bounds Max_N");
      Check (Keys_In_Range (Ok), "Keys_In_Range tiny");
      Check (Keys_In_Range (Empty), "Keys_In_Range empty");
      Check (not Keys_In_Range (Wide), "Keys_In_Range false when span>Max");
      Check (Keys_In_Range ([0, Max_Range - 1]),
             "Keys_In_Range true at exact Max_Range");
   end;

   ---------------------------------------------------------------------
   Section ("8. Almost sorted / gapped / dense exams");
   ---------------------------------------------------------------------
   Expect_Sorted ([1, 2, 3, 5, 4], "almost sorted swap");
   Expect_Sorted ([10, 20, 30, 40, 50, 5], "gapped then low");
   Expect_Sorted ([0, 100, 50, 25, 75], "exam-score-ish");
   Expect_Sorted
     ([90, 85, 90, 70, 85, 100, 70, 60, 100, 55], "score dups");

   New_Line;
   Put_Line ("Results: "
             & Natural'Image (Pass_Count) & " PASS,"
             & Natural'Image (Fail_Count) & " FAIL");
   if Fail_Count > 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
