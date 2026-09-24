--  Standalone test suite for Spaghetti_Sort (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Spaghetti_Sort; use Spaghetti_Sort;

procedure Tests is

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

   --  Simple insertion-sort reference for general Integers.
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

   function Extraction_Raises (A : Element_Array) return Boolean is
      T : Element_Array := A;
   begin
      Sort_Extraction (T);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Extraction_Raises;

   procedure Expect_Height_Sorted (Src : Element_Array; Label : String) is
      A : Element_Array := Copy_Of (Src);
      R : Element_Array := Copy_Of (Src);
   begin
      Sort (A);
      Reference_Sort (R);
      Check (Is_Sorted (A), Label & " Is_Sorted");
      Check (Same (A, R), Label & " matches reference");
   end Expect_Height_Sorted;

   procedure Expect_Extraction_Sorted
     (Src : Element_Array; Label : String)
   is
      A : Element_Array := Copy_Of (Src);
      R : Element_Array := Copy_Of (Src);
   begin
      Sort_Extraction (A);
      Reference_Sort (R);
      Check (Is_Sorted (A), Label & " Is_Sorted");
      Check (Same (A, R), Label & " matches reference");
   end Expect_Extraction_Sorted;

   --  Deterministic LCG (keeps values in a safe nonnegative range).
   Seed : Natural := 1_234_567;

   function Next_Mod (Modulus : Positive) return Natural is
      --  Numerical Recipes LCG step, masked to avoid Integer overflow.
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
   ---------------------------------------------------------------------
   Section ("1. Empty and singleton");
   ---------------------------------------------------------------------
   declare
      E : Element_Array (1 .. 0);
      S : Element_Array (1 .. 1) := [42];
      Z : Element_Array (1 .. 1) := [0];
   begin
      Check (Is_Sorted (E), "empty Is_Sorted");
      Sort (E);
      Check (Is_Sorted (E), "empty Sort no-op");
      Sort_Extraction (E);
      Check (Is_Sorted (E), "empty Sort_Extraction no-op");
      Check (Is_Sorted (S), "singleton Is_Sorted");
      Sort (S);
      Check (S (1) = 42, "singleton Sort preserves");
      Sort_Extraction (Z);
      Check (Z (1) = 0, "singleton extraction preserves 0");
   end;

   ---------------------------------------------------------------------
   Section ("2. Height-bin basic permutations");
   ---------------------------------------------------------------------
   Expect_Height_Sorted ([1, 2, 3], "already sorted");
   Expect_Height_Sorted ([3, 2, 1], "reversed");
   Expect_Height_Sorted ([2, 1, 3], "rotated");
   Expect_Height_Sorted ([5, 1, 4, 2, 3], "mixed 5");
   Expect_Height_Sorted ([0, 0, 0], "all zeros");
   Expect_Height_Sorted ([7, 7, 7, 7], "all equal 7");

   ---------------------------------------------------------------------
   Section ("3. Duplicates");
   ---------------------------------------------------------------------
   Expect_Height_Sorted ([3, 1, 3, 2, 1, 3], "dups mixed");
   Expect_Height_Sorted ([9, 0, 9, 0, 5], "boundary 0 and 9");
   Expect_Height_Sorted ([1, 1, 2, 2, 3, 3], "pairs ascending");
   Expect_Height_Sorted ([3, 3, 2, 2, 1, 1], "pairs descending");

   ---------------------------------------------------------------------
   Section ("4. Extraction for general Integers");
   ---------------------------------------------------------------------
   Expect_Extraction_Sorted ([-3, -1, -2], "negatives");
   Expect_Extraction_Sorted ([-5, 0, 5, -2, 3], "mixed signs");
   Expect_Extraction_Sorted ([100, -100, 0], "wide range");
   Expect_Extraction_Sorted ([2, 2, -2, -2, 0], "signed dups");
   Expect_Extraction_Sorted (
     [Integer'First + 10, -1, Integer'Last - 10], "near extremes");

   ---------------------------------------------------------------------
   Section ("5. Both methods agree on nonnegative data");
   ---------------------------------------------------------------------
   declare
      Src : constant Element_Array := [8, 3, 5, 1, 9, 2, 7, 4, 6, 0];
      H   : Element_Array := Src;
      X   : Element_Array := Src;
   begin
      Sort (H);
      Sort_Extraction (X);
      Check (Same (H, X), "height vs extraction agree");
      Check (Is_Sorted (H), "agreed result sorted");
   end;

   ---------------------------------------------------------------------
   Section ("6. Pseudo-random sequences vs reference");
   ---------------------------------------------------------------------
   for Trial in 1 .. 8 loop
      declare
         N   : constant Positive := 3 + (Trial mod 12);
         Src : Element_Array (1 .. N);
      begin
         for I in Src'Range loop
            Src (I) := Integer (Next_Mod (50));
         end loop;
         Expect_Height_Sorted (Src, "rand height #" & Trial'Image);
         Expect_Extraction_Sorted (Src, "rand extract #" & Trial'Image);
      end;
   end loop;

   ---------------------------------------------------------------------
   Section ("7. Invalid_Argument — oversize and bad keys");
   ---------------------------------------------------------------------
   declare
      Big : constant Element_Array (1 .. Max_Length + 1) := [others => 0];
      Neg : constant Element_Array := [1, -1, 2];
      Hi  : constant Element_Array := [1, Max_Key + 1, 2];
   begin
      Check (Sort_Raises (Big), "Sort raises on oversize");
      Check (Extraction_Raises (Big), "Extraction raises on oversize");
      Check (Sort_Raises (Neg), "Sort raises on negative key");
      Check (Sort_Raises (Hi), "Sort raises on key > Max_Key");
      declare
         T : Element_Array := Neg;
      begin
         Sort_Extraction (T);
         Check (Is_Sorted (T) and then T (T'First) = -1, "extraction ok on neg");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("8. Is_Sorted edge cases");
   ---------------------------------------------------------------------
   Check (Is_Sorted ([1, 2, 2, 3]), "nondecreasing with dups");
   Check (not Is_Sorted ([1, 3, 2]), "detects inversion");
   Check (not Is_Sorted ([2, 1]), "pair inversion");
   Check (Is_Sorted ([0]), "single zero");
   Check (Is_Sorted ([-5, -5, -1, 0, 10]), "signed ascending");

   ---------------------------------------------------------------------
   Section ("9. Index bounds and Sort_Height rename");
   ---------------------------------------------------------------------
   declare
      A : Element_Array (0 .. 4) := [4, 3, 2, 1, 0];
      B : Element_Array (10 .. 14) := [5, 4, 3, 2, 1];
   begin
      Sort (A);
      Check (Is_Sorted (A) and then A (0) = 0 and then A (4) = 4,
             "0-based height sort");
      Sort_Height (B);
      Check (Is_Sorted (B) and then B (10) = 1 and then B (14) = 5,
             "Sort_Height rename on 10-based");
   end;

   ---------------------------------------------------------------------
   Section ("10. Larger height-bin run");
   ---------------------------------------------------------------------
   declare
      N   : constant Positive := 200;
      Src : Element_Array (1 .. N);
   begin
      for I in Src'Range loop
         Src (I) := Integer (Next_Mod (1000));
      end loop;
      Expect_Height_Sorted (Src, "n=200 height");
      Expect_Extraction_Sorted (Src, "n=200 extraction");
   end;

   ---------------------------------------------------------------------
   Section ("11. Idempotence");
   ---------------------------------------------------------------------
   declare
      A : Element_Array := [4, 1, 3, 2, 0, 5];
   begin
      Sort (A);
      declare
         Once : constant Element_Array := A;
      begin
         Sort (A);
         Check (Same (A, Once), "Sort idempotent");
         Sort_Extraction (A);
         Check (Same (A, Once), "Extraction on sorted idempotent");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("12. Max_Key boundary value");
   ---------------------------------------------------------------------
   declare
      A : Element_Array := [0, Max_Key, Max_Key / 2, 1];
   begin
      Sort (A);
      Check (A (A'First) = 0 and then A (A'Last) = Max_Key,
             "includes 0 and Max_Key");
      Check (Is_Sorted (A), "Max_Key sample sorted");
   end;

   New_Line;
   Put_Line
     ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image
      & " FAIL");

   if Fail_Count /= 0 then
      raise Program_Error with "Spaghetti_Sort tests failed";
   end if;
end Tests;
