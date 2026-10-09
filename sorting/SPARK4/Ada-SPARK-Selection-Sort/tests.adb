--  Standalone test suite for Selection_Sort (SPARK port).
--  Preconditions replace exceptions; only valid call paths are exercised.
--  Any A'First in 1 .. Max_N (section 13 shifts origins); Max_N = 64. Sortedness is proved by SPARK;
--  multiset / permutation equality is checked here.

pragma Ada_2022;

with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Selection_Sort; use Selection_Sort;

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

   --  Independent insertion-sort reference (ascending).
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

   --  Descending reference via reverse of ascending sort.
   procedure Reference_Sort_Descending (A : in out Element_Array) is
   begin
      Reference_Sort (A);
      if A'Length <= 1 then
         return;
      end if;
      declare
         Lo : Natural := A'First;
         Hi : Natural := A'Last;
         T  : Integer;
      begin
         while Lo < Hi loop
            T := A (Lo);
            A (Lo) := A (Hi);
            A (Hi) := T;
            Lo := Lo + 1;
            Hi := Hi - 1;
         end loop;
      end;
   end Reference_Sort_Descending;

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
      Sort (A);
      Reference_Sort (R);
      Check (Boo (Is_Sorted (A)), Label & " Is_Sorted");
      Check (Same (A, R), Label & " matches reference");
      Check (Is_Permutation (A, O), Label & " permutation");
   end Expect_Sorted;

   procedure Expect_Desc_Sorted (Src : Element_Array; Label : String) is
      A : Element_Array := Copy_Of (Src);
      R : Element_Array := Copy_Of (Src);
      O : constant Element_Array := Copy_Of (Src);
   begin
      Sort_Descending (A);
      Reference_Sort_Descending (R);
      Check (Boo (Is_Sorted_Descending (A)), Label & " Is_Sorted_Descending");
      Check (Same (A, R), Label & " desc matches reference");
      Check (Is_Permutation (A, O), Label & " desc permutation");
   end Expect_Desc_Sorted;

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


   --  Same contents placed at Origin .. Origin + Len - 1. Sorting the
   --  shifted copy must give the reference sort of Src, slot for slot.
   function Shifted_Ok (Src : Element_Array; Origin : Positive)
     return Boolean
   is
      A : Element_Array (Origin .. Origin + Src'Length - 1);
      R : Element_Array := Copy_Of (Src);
   begin
      for K in 0 .. Src'Length - 1 loop
         A (Origin + K) := Src (Src'First + K);
      end loop;
      Sort (A);
      Reference_Sort (R);
      return Is_Sorted (A) and then Same (A, R);
   end Shifted_Ok;

begin
   Put_Line ("Selection_Sort (SPARK) tests");
   Put_Line ("============================");

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
      Check (Boo (Is_Sorted_Descending (Empty)), "empty Is_Sorted_Descending");
      Sort (Empty);
      Check (Boo (Is_Sorted (Empty)), "empty after Sort");
      Sort_Descending (Empty);
      Check (Boo (Is_Sorted_Descending (Empty)), "empty after Sort_Descending");
      Check (In_Bounds (One), "singleton In_Bounds");
      Check (Boo (Is_Sorted (One)), "singleton Is_Sorted");
      Sort (One);
      Check (Int (One (One'First)) = 42, "singleton value preserved");
      Check (Boo (Is_Sorted (One)), "singleton after Sort");
      Sort_Descending (Neg);
      Check (Int (Neg (Neg'First)) = -7, "negative singleton preserved");
      Check (Boo (Is_Sorted_Descending (Neg)), "negative singleton desc");
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
   Section ("3. Wikipedia worked example");
   ---------------------------------------------------------------------
   --  Wikipedia: 64 25 12 22 11 → 11 12 22 25 64
   declare
      A : Element_Array := [64, 25, 12, 22, 11];
      O : constant Element_Array := [64, 25, 12, 22, 11];
   begin
      Sort (A);
      Check (Same (A, [11, 12, 22, 25, 64]), "wiki example sorts to known");
      Check (Boo (Is_Sorted (A)), "wiki example Is_Sorted");
      Check (Is_Permutation (A, O), "wiki example permutation");
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
   Section ("6. Sort_Descending");
   ---------------------------------------------------------------------
   Expect_Desc_Sorted ([1, 2, 3, 4, 5], "asc input desc");
   Expect_Desc_Sorted ([5, 4, 3, 2, 1], "already desc");
   Expect_Desc_Sorted ([3, 1, 4, 1, 5], "mixed desc");
   Expect_Desc_Sorted ([-1, 0, 1], "signed desc");
   declare
      A : Element_Array := [64, 25, 12, 22, 11];
   begin
      Sort_Descending (A);
      Check (Same (A, [64, 25, 22, 12, 11]), "wiki example descending");
      Check (Boo (Is_Sorted_Descending (A)), "wiki desc Is_Sorted_Descending");
   end;

   ---------------------------------------------------------------------
   Section ("7. Is_Sorted predicates");
   ---------------------------------------------------------------------
   Check (Boo (Is_Sorted ([1, 2, 2, 3])), "nondecreasing true");
   Check (not Boo (Is_Sorted ([1, 3, 2])), "unsorted ascending false");
   Check (Boo (Is_Sorted_Descending ([9, 5, 5, 1])), "nonincreasing true");
   Check (not Boo (Is_Sorted_Descending ([9, 1, 5])), "unsorted descending false");
   Check (Boo (Is_Sorted ([7])), "singleton true");
   Check (Boo (Is_Sorted ([0, 0, 0])), "zeros nondecreasing");
   Check (not Boo (Is_Sorted ([0, 2, 1])), "zero then inversion false");
   Check (Boo (Is_Sorted ([-3, -2, -1, 0])), "negatives ascending");
   declare
      E : Element_Array (1 .. 0);
   begin
      Check (Boo (Is_Sorted (E)), "empty true");
   end;

   ---------------------------------------------------------------------
   Section ("8. In_Bounds / Max_N shape");
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
   Section ("9. Random arrays vs reference");
   ---------------------------------------------------------------------
   Expect_Sorted (Random_Array (2, -100, 100), "random n=2");
   Expect_Sorted (Random_Array (3, -100, 100), "random n=3");
   Expect_Sorted (Random_Array (5, -100, 100), "random n=5");
   Expect_Sorted (Random_Array (8, -1000, 1000), "random n=8");
   Expect_Sorted (Random_Array (16, -1000, 1000), "random n=16");
   Expect_Sorted (Random_Array (32, -50, 50), "random n=32");
   Expect_Sorted (Random_Array (64, -20, 20), "random n=64");
   Expect_Sorted (Random_Array (40, 0, 10), "random n=40 many dups");
   Expect_Desc_Sorted (Random_Array (20, -200, 200), "random desc n=20");
   Expect_Desc_Sorted (Random_Array (40, -10, 10), "random desc n=40");
   Expect_Desc_Sorted (Random_Array (64, -5, 5), "random desc n=64");

   ---------------------------------------------------------------------
   Section ("10. Idempotence");
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
      A : Element_Array := [1, 2, 3, 4, 5, 6];
   begin
      Sort_Descending (A);
      declare
         B : constant Element_Array := Copy_Of (A);
      begin
         Sort_Descending (A);
         Check (Same (A, B), "Sort_Descending idempotent");
         Check (Boo (Is_Sorted_Descending (A)), "desc idempotent still sorted");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("11. Nearly sorted / single inversion");
   ---------------------------------------------------------------------
   Expect_Sorted ([1, 2, 3, 5, 4], "single swap near end");
   Expect_Sorted ([2, 1, 3, 4, 5], "single swap near start");
   Expect_Sorted ([1, 2, 2, 2, 1], "dups with inversion");

   ---------------------------------------------------------------------
   Section ("12. Power-of-two and odd lengths");
   ---------------------------------------------------------------------
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
      A : Element_Array (1 .. 64);
   begin
      for I in A'Range loop
         A (I) := 65 - I;
      end loop;
      Expect_Sorted (A, "reverse n=64");
   end;


   ---------------------------------------------------------------------
   Section ("13. Shifted origins (A'First > 1, flush to Max_N)");
   ---------------------------------------------------------------------
   --  Origins 2, 7, Max_N / 2 + 1 (every length) and Max_N - Len + 1
   --  (slice ends at Index'Last), for equal / sorted / reverse / organ /
   --  random inputs.
   declare
      type Origin_List is array (Positive range <>) of Positive;
      Fixed : constant Origin_List := [2, 7, Max_N / 2 + 1];
      Pattern_Names : constant array (1 .. 5) of String (1 .. 8) :=
        ["equal   ", "sorted  ", "reverse ", "organ   ", "random  "];
      Ok    : Boolean;
      Cases : Natural;
      Rand  : Natural := 12_345;

      function Make (P : Positive; Len : Natural) return Element_Array is
         A : Element_Array (1 .. Len);
      begin
         for I in A'Range loop
            case P is
               when 1 => A (I) := 42;
               when 2 => A (I) := I;
               when 3 => A (I) := Len - I + 1;
               when 4 => A (I) := (if 2 * I <= Len + 1 then I else Len - I + 1);
               when others =>
                  Rand := (Rand * 1_103 + 12_345) mod 65_521;
                  A (I) := Rand mod 41 - 20;
            end case;
         end loop;
         return A;
      end Make;
   begin
      for P in Pattern_Names'Range loop
         for O of Fixed loop
            Ok := True;
            Cases := 0;
            for Len in 0 .. Max_N - O + 1 loop
               Cases := Cases + 1;
               if not Shifted_Ok (Make (P, Len), O) then
                  Ok := False;
                  Put_Line ("    mismatch origin" & O'Image & " len"
                            & Len'Image);
               end if;
            end loop;
            Check (Ok, "origin" & O'Image & " " & Pattern_Names (P)
                   & " lens 0 .." & Natural'Image (Max_N - O + 1)
                   & " (" & Cases'Image & " cases)");
         end loop;
         Ok := True;
         for Len in 1 .. Max_N - 1 loop
            if not Shifted_Ok (Make (P, Len), Max_N - Len + 1) then
               Ok := False;
               Put_Line ("    mismatch flush len" & Len'Image);
            end if;
         end loop;
         Check (Ok, "flush to Max_N " & Pattern_Names (P) & " lens 1 .."
                & Natural'Image (Max_N - 1));
      end loop;
   end;
   declare
      Tail : Element_Array (Max_N - 5 .. Max_N) := [9, -3, 9, 0, -3, 7];
   begin
      Check (In_Bounds (Tail), "Tail(Max_N-5 .. Max_N) In_Bounds");
      Sort (Tail);
      Check (Same (Tail, Element_Array'([-3, -3, 0, 7, 9, 9])),
             "Tail(Max_N-5 .. Max_N) sorted in place");
   end;
   declare
      Tail : Element_Array (Max_N - 5 .. Max_N) := [9, -3, 9, 0, -3, 7];
      Mid  : Element_Array (7 .. 12) := [9, -3, 9, 0, -3, 7];
   begin
      Sort_Descending (Tail);
      Sort_Descending (Mid);
      Check (Same (Tail, Element_Array'([9, 9, 7, 0, -3, -3]))
             and then Same (Mid, Element_Array'([9, 9, 7, 0, -3, -3])),
             "Sort_Descending at origins 7 and Max_N-5");
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
      raise Program_Error with "Selection_Sort tests failed";
   end if;
end Tests;
