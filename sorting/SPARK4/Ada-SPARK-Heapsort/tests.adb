--  Standalone test suite for Heapsort (SPARK port).
--  Preconditions replace exceptions; only valid call paths are exercised.
--  A may start at any origin (Max_N = 64). Sortedness is proved by SPARK;
--  multiset / permutation equality is checked here. Heapsort is
--  unstable, so tagged equal keys are only checked as a permutation.

pragma Ada_2022;

with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Heapsort; use Heapsort;

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

   --  True iff A (A'First .. Heap_Last) is a max-heap; the children of
   --  slot I are A'First + 2 * (I - A'First) + 1 and the next slot.
   function Is_Max_Heap
     (A : Element_Array; Heap_Last : Natural) return Boolean
   is
      Left : Natural;
   begin
      if A'Length = 0 or else Heap_Last < A'First then
         return True;
      end if;
      for I in A'First .. Heap_Last loop
         Left := A'First + 2 * (I - A'First) + 1;
         if Left <= Heap_Last then
            if A (I) < A (Left) then
               return False;
            end if;
            if Left < Heap_Last and then A (I) < A (Left + 1) then
               return False;
            end if;
         end if;
      end loop;
      return True;
   end Is_Max_Heap;

   procedure Expect_Sorted (Src : Element_Array; Label : String) is
      A : Element_Array := Copy_Of (Src);
      R : Element_Array := Copy_Of (Src);
      O : constant Element_Array := Copy_Of (Src);
   begin
      Sort (A);
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
   Seed : Natural := AA_Seed (1_234_567);

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
   Put_Line ("Heapsort (SPARK) tests");
   Put_Line ("======================");

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
      Sort (Empty);
      Check (Boo (Is_Sorted (Empty)), "empty after Sort");
      Heapify (Empty);
      Check (Boo (Is_Sorted (Empty)), "empty Heapify no-op");
      Check (In_Bounds (One), "singleton In_Bounds");
      Check (Boo (Is_Sorted (One)), "singleton Is_Sorted");
      Sort (One);
      Check (Int (One (1)) = 42, "singleton value preserved");
      Check (Boo (Is_Sorted (One)), "singleton after Sort");
      Sort (Neg);
      Check (Int (Neg (1)) = -7, "negative singleton preserved");
      Heapify (Neg);
      Check (Int (Neg (1)) = -7, "negative singleton Heapify");
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

   ---------------------------------------------------------------------
   Section ("3. Classic worked example");
   ---------------------------------------------------------------------
   declare
      A : Element_Array := [64, 25, 12, 22, 11];
      O : constant Element_Array := Copy_Of (A);
   begin
      Sort (A);
      Check (Same (A, [11, 12, 22, 25, 64]), "worked example sorts to known");
      Check (Boo (Is_Sorted (A)), "worked example Is_Sorted");
      Check (Is_Permutation (A, O), "worked example permutation");
   end;

   ---------------------------------------------------------------------
   Section ("4. Two-element and small permutations");
   ---------------------------------------------------------------------
   Expect_Sorted ([1, 2], "two ascending");
   Expect_Sorted ([2, 1], "two descending");
   Expect_Sorted ([1, 1], "two equal");
   Expect_Sorted ([3, 1, 2], "perm 3,1,2");
   Expect_Sorted ([2, 3, 1], "perm 2,3,1");
   Expect_Sorted ([1, 3, 2], "perm 1,3,2");

   ---------------------------------------------------------------------
   Section ("5. Negatives and extreme Integers");
   ---------------------------------------------------------------------
   Expect_Sorted ([-5, -1, -3, -2, -4], "all negatives");
   Expect_Sorted ([Integer'First, 0, Integer'Last], "extremes trio");
   Expect_Sorted
     ([Integer'Last, Integer'First, Integer'First + 1, -1],
      "extremes quartet");

   ---------------------------------------------------------------------
   Section ("6. Heapify / Sift_Down invariants");
   ---------------------------------------------------------------------
   --  The checker itself, on arrays that do not start at 1 (V&V sweep,
   --  agent A3): with A'First = 2 the children of slot 2 are 3 and 4.
   declare
      Two : Element_Array (2 .. 4) := [1, 2, 0];
      Five : constant Element_Array (5 .. 9) := [9, 8, 7, 1, 9];
   begin
      Check (not Is_Max_Heap (Two, 4), "Is_Max_Heap rejects child 2 under root 1 (A'First = 2)");
      Two := [3, 2, 1];
      Check (Is_Max_Heap (Two, 4), "Is_Max_Heap accepts 3 2 1 (A'First = 2)");
      --  slot 8 (value 1) is the left child of slot 6 (value 8), slot 9
      --  (value 9) the right child: 9 > 8 breaks the heap.
      Check (not Is_Max_Heap (Five, 9), "Is_Max_Heap rejects 9 8 7 1 9 (A'First = 5)");
      Check (Is_Max_Heap (Five, 8), "Is_Max_Heap accepts 9 8 7 1 (A'First = 5)");
   end;
   declare
      A : Element_Array := [3, 1, 4, 1, 5, 9, 2, 6, 5];
   begin
      Heapify (A);
      Check (Is_Max_Heap (A, A'Last), "Heapify builds max-heap");
      Check (A (1) >= A (2), "root >= left child");
   end;
   declare
      A : Element_Array := [1, 9, 8, 7, 6];
   begin
      Sift_Down (A, 1, A'Last);
      Check (Is_Max_Heap (A, A'Last), "Sift_Down repairs damaged root");
      Check (Int (A (1)) = 9, "Sift_Down promotes maximum to root");
   end;
   declare
      A : Element_Array := [10, 8, 9, 7, 6, 5, 4];
      B : constant Element_Array := Copy_Of (A);
   begin
      Check (Is_Max_Heap (A, A'Last), "prebuilt heap recognized");
      Sift_Down (A, 1, A'Last);
      Check (Same (A, B), "Sift_Down no-op on valid heap");
   end;

   ---------------------------------------------------------------------
   Section ("7. Is_Sorted / In_Bounds predicates");
   ---------------------------------------------------------------------
   Check (Boo (Is_Sorted ([1, 2, 2, 3])), "nondecreasing true");
   Check (not Boo (Is_Sorted ([1, 3, 2])), "unsorted ascending false");
   Check (Boo (Is_Sorted ([Integer'First, Integer'First])),
          "equal extremes sorted");
   Check (not Boo (Is_Sorted ([0, -1])), "descending pair not sorted");
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
   Section ("8. Random arrays vs reference");
   ---------------------------------------------------------------------
   Expect_Sorted (Random_Array (2, -100, 100), "random n=2");
   Expect_Sorted (Random_Array (3, -100, 100), "random n=3");
   Expect_Sorted (Random_Array (5, -100, 100), "random n=5");
   Expect_Sorted (Random_Array (8, -1000, 1000), "random n=8");
   Expect_Sorted (Random_Array (16, -1000, 1000), "random n=16");
   Expect_Sorted (Random_Array (32, -50, 50), "random n=32");
   Expect_Sorted (Random_Array (64, -20, 20), "random n=64");
   Expect_Sorted (Random_Array (50, 0, 10), "random n=50 many dups");
   Expect_Sorted (Random_Array (40, 1, 1), "random all identical");
   Expect_Sorted (Random_Array (63, -100, 100), "random n=63");
   Expect_Sorted (Random_Array (7, -5, 5), "random n=7");
   Expect_Sorted (Random_Array (12, -1000, 1000), "random n=12");

   ---------------------------------------------------------------------
   Section ("9. Idempotence and extract-max phase");
   ---------------------------------------------------------------------
   declare
      A : Element_Array := [9, 4, 1, 8, 2, 7, 3];
      B : Element_Array (A'Range);
   begin
      Sort (A);
      B := A;
      Sort (A);
      Check (Same (A, B), "Sort twice is idempotent");
      Check (Boo (Is_Sorted (A)), "idempotent result still sorted");
   end;
   declare
      A : Element_Array := [4, 10, 3, 5, 1];
      T : Integer;
   begin
      Heapify (A);
      Check (Is_Max_Heap (A, A'Last), "before extract max-heap");
      Check (Int (A (1)) = 10, "heap root is global maximum");
      T := A (1);
      A (1) := A (A'Last);
      A (A'Last) := T;
      Sift_Down (A, 1, A'Last - 1);
      Check (Int (A (A'Last)) = 10, "extract-max places global max at end");
      Check (Is_Max_Heap (A, A'Last - 1), "heap after one extract");
   end;

   ---------------------------------------------------------------------
   Section ("10. Nearly sorted / edge patterns");
   ---------------------------------------------------------------------
   Expect_Sorted ([1, 2, 3, 5, 4], "single swap near end");
   Expect_Sorted ([2, 1, 3, 4, 5], "single swap near start");
   Expect_Sorted ([1, 2, 2, 2, 1], "dups with inversion");
   Expect_Sorted ([1, 2, 4, 8, 16, 32, 64, 128, 256, 3],
                  "powers then disrupt");
   Expect_Sorted ([100, 1, 99, 2, 98, 3, 97, 4, 96, 5], "sawtooth");
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
      A : Element_Array (1 .. 64);
   begin
      for I in A'Range loop
         A (I) := 65 - I;
      end loop;
      Expect_Sorted (A, "reverse n=64");
   end;

   Section ("11. Shifted origins (incl. flush-to-Live_Index'Last)");
   declare
      Origins : constant array (1 .. 4) of Natural := [2, 7, 33, 0];
      Ok_Shift : Boolean := True;
      Cases   : Natural := 0;
      Seed    : Natural := 12345;
      function Next (M : Positive) return Natural is
         X : Natural;
      begin
         X := Natural ((Long_Long_Integer (Seed) * 1_103_515_245 + 12_345)
                       mod 2_147_483_647);
         Seed := X;
         return X rem M;
      end Next;
   begin
      for Trial in 1 .. 80 loop
         declare
            Len : constant Positive := 1 + Next (Max_N);
            A1  : Element_Array (1 .. Len);
         begin
            for K in A1'Range loop
               A1 (K) := Integer (Next (200)) - 100;
            end loop;
            for O_I in Origins'Range loop
               declare
                  F  : constant Positive :=
                    (if Origins (O_I) = 0 then Max_N - Len + 1
                     else Positive'Min (Origins (O_I), Max_N - Len + 1));
                  AS : Element_Array (F .. F + Len - 1) := A1;
                  A1c : Element_Array := A1;
               begin
                  Sort (A1c);
                  Sort (AS);
                  Cases := Cases + 1;
                  for K in 0 .. Len - 1 loop
                     if AS (F + K) /= A1c (1 + K) then
                        Ok_Shift := False;
                     end if;
                  end loop;
               end;
            end loop;
         end;
      end loop;
      Check (Ok_Shift, "Sort on shifted copies (2,7,33,Max_N-Len+1) = 1-based;"
             & Cases'Image & " cases");
      declare
         Tail : Element_Array (Max_N - 5 .. Max_N);
         Ref  : Element_Array (1 .. 6) := [9, 1, 8, 2, 7, 3];
      begin
         for K in 0 .. 5 loop
            Tail (Max_N - 5 + K) := Ref (1 + K);
         end loop;
         Sort (Tail);
         Sort (Ref);
         Check (Same (Tail, Ref), "flush-to-Max_N Sort = 1-based");
         Check (Is_Sorted (Tail) and then In_Bounds (Tail),
                "flush-to-Max_N Is_Sorted/In_Bounds");
      end;
   end;

   Section ("Is_Perm (Post) against sorted copies: every pair of arrays of length 0 .. 4 over -1 .. 1, origins 1 and 7");
   declare
      Bad   : Natural := 0;
      Cases : Natural := 0;
   begin
      for Len in 0 .. 4 loop
         for Origin in 1 .. 2 loop
            for CA in 0 .. 3 ** Len - 1 loop
               for CB in 0 .. 3 ** Len - 1 loop
                  declare
                     First : constant Positive := (if Origin = 1 then 1 else 7);
                     A, B  : Element_Array (First .. First + Len - 1);
                     X     : Natural := CA;
                     Y     : Natural := CB;
                  begin
                     for I in A'Range loop
                        A (I) := X mod 3 - 1;
                        B (I) := Y mod 3 - 1;
                        X := X / 3;
                        Y := Y / 3;
                     end loop;
                     Cases := Cases + 1;
                     if Is_Perm (A, B) /= Is_Permutation (A, B) then
                        Bad := Bad + 1;
                     end if;
                  end;
               end loop;
            end loop;
         end loop;
      end loop;
      Check (Bad = 0 and then Cases = 14_762,
             "Is_Perm = sorted-copy comparison on" & Cases'Image & " pairs");
      Check (not Is_Perm (Element_Array'([3, 1, 2]), Element_Array'([0, 0, 0])),
             "Is_Perm rejects an all-zeros result");
      Check (not Is_Perm (Element_Array'([1, 1, 2]), Element_Array'([1, 2, 2])),
             "Is_Perm compares counts, not just values");
   end;

   New_Line;
   Put_Line
     ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image
      & " FAIL");

   if Fail_Count /= 0 then
      raise Program_Error with "Heapsort tests failed";
   end if;
end Tests;
