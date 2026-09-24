--  Standalone test suite for Fisher_Yates_Shuffle (main program).

pragma Ada_2022;

with Ada.Text_IO;       use Ada.Text_IO;
with Interfaces;        use Interfaces;
with Fisher_Yates_Shuffle; use Fisher_Yates_Shuffle;

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

   --  Library-level RNG helpers live in nested package at library depth
   --  via a package declared outside; see Test_RNG below the procedure.
   --  Here we only call through Random_Index values obtained from it.

   package Test_RNG is
      Inject_Seed : Unsigned_64 := 0;

      function Injected_Next (Lo, Hi : Natural) return Natural;
      function Always_Lo (Lo, Hi : Natural) return Natural;
      function Always_Hi (Lo, Hi : Natural) return Natural;
      function Out_Of_Range (Lo, Hi : Natural) return Natural;
   end Test_RNG;

   package body Test_RNG is
      function Injected_Next (Lo, Hi : Natural) return Natural is
         Span : constant Natural := Hi - Lo;
         R    : Unsigned_64;
         Off  : Natural;
      begin
         if Span = 0 then
            return Lo;
         end if;
         Inject_Seed :=
           Inject_Seed * 6_364_136_223_846_793_005 + 1;
         R := Inject_Seed;
         Off := Natural (R mod Unsigned_64 (Span + 1));
         return Lo + Off;
      end Injected_Next;

      function Always_Lo (Lo, Hi : Natural) return Natural is
         pragma Unreferenced (Hi);
      begin
         return Lo;
      end Always_Lo;

      function Always_Hi (Lo, Hi : Natural) return Natural is
         pragma Unreferenced (Lo);
      begin
         return Hi;
      end Always_Hi;

      function Out_Of_Range (Lo, Hi : Natural) return Natural is
         pragma Unreferenced (Lo, Hi);
      begin
         return Natural'Last;
      end Out_Of_Range;
   end Test_RNG;

begin
   ---------------------------------------------------------------------
   Section ("1. Empty and singleton (no-op)");
   ---------------------------------------------------------------------
   declare
      Empty : Element_Array (1 .. 0);
      One   : Element_Array := [42];
      Seed  : Unsigned_64 := 7;
      Orig  : constant Element_Array := [42];
   begin
      Shuffle (Empty, Seed);
      Check (Empty'Length = 0, "empty LCG: still empty");
      Check (Is_Permutation_Of (Empty, Element_Array'(1 .. 0 => <>)),
             "empty Is_Permutation_Of empty");

      Shuffle (One, Seed);
      Check (Same (One, Orig), "singleton LCG: unchanged");
      Check (Is_Permutation_Of (One, Orig), "singleton is perm of self");

      Shuffle (Empty, Test_RNG.Injected_Next'Access);
      Check (Empty'Length = 0, "empty access: still empty");

      One := [42];
      Shuffle (One, Test_RNG.Always_Hi'Access);
      Check (Same (One, Orig), "singleton access: unchanged");
   end;

   ---------------------------------------------------------------------
   Section ("2. Multiset preserved (LCG)");
   ---------------------------------------------------------------------
   declare
      Seed : Unsigned_64;
   begin
      declare
         A : Element_Array := [1, 2, 3, 4, 5];
         O : constant Element_Array := [1, 2, 3, 4, 5];
      begin
         Seed := 1;
         Shuffle (A, Seed);
         Check (Is_Permutation_Of (A, O), "1..5 is permutation");
      end;

      declare
         A : Element_Array := [3, 1, 4, 1, 5, 9, 2, 6];
         O : constant Element_Array := [3, 1, 4, 1, 5, 9, 2, 6];
      begin
         Seed := 99;
         Shuffle (A, Seed);
         Check (Is_Permutation_Of (A, O), "duplicates preserved");
      end;

      declare
         A : Element_Array := [-2, 0, 7, -2, 100];
         O : constant Element_Array := [-2, 0, 7, -2, 100];
      begin
         Seed := 12345;
         Shuffle (A, Seed);
         Check (Is_Permutation_Of (A, O), "negatives / zero preserved");
      end;

      declare
         A : Element_Array := [10, 10, 10, 10];
         O : constant Element_Array := [10, 10, 10, 10];
      begin
         Seed := 55;
         Shuffle (A, Seed);
         Check (Is_Permutation_Of (A, O), "all-equal preserved");
         Check (Same (A, O), "all-equal still equal after shuffle");
      end;

      declare
         A : Element_Array (0 .. 5) := [0, 1, 2, 3, 4, 5];
         O : constant Element_Array := [0, 1, 2, 3, 4, 5];
      begin
         Seed := 2;
         Shuffle (A, Seed);
         Check (Is_Permutation_Of (A, O), "0-based bounds preserved");
      end;

      declare
         A : Element_Array (100 .. 104) := [5, 4, 3, 2, 1];
         O : constant Element_Array := [5, 4, 3, 2, 1];
      begin
         Seed := 3;
         Shuffle (A, Seed);
         Check (Is_Permutation_Of (A, O), "high bounds preserved");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("3. Fixed seed is deterministic");
   ---------------------------------------------------------------------
   declare
      Seed1 : Unsigned_64;
      Seed2 : Unsigned_64;
      Base  : constant Element_Array :=
        [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
      A1    : Element_Array := Copy_Of (Base);
      A2    : Element_Array := Copy_Of (Base);
   begin
      Seed1 := 42;
      A1 := Copy_Of (Base);
      Shuffle (A1, Seed1);

      Seed2 := 42;
      A2 := Copy_Of (Base);
      Shuffle (A2, Seed2);

      Check (Same (A1, A2), "same seed → identical permutation");
      Check (Is_Permutation_Of (A1, Base), "det. result is a perm");

      Seed1 := 42;
      A1 := Copy_Of (Base);
      Shuffle (A1, Seed1);
      Seed1 := 42;
      A2 := Copy_Of (Base);
      Shuffle (A2, Seed1);
      Check (Same (A1, A2), "re-seed again → identical");
   end;

   ---------------------------------------------------------------------
   Section ("4. Different seeds usually differ");
   ---------------------------------------------------------------------
   declare
      Base  : constant Element_Array :=
        [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
      A1 : Element_Array := Copy_Of (Base);
      A2 : Element_Array := Copy_Of (Base);
      A3 : Element_Array := Copy_Of (Base);
      S1, S2, S3 : Unsigned_64;
      Differ_Count : Natural := 0;
   begin
      S1 := 1;
      A1 := Copy_Of (Base);
      Shuffle (A1, S1);

      S2 := 2;
      A2 := Copy_Of (Base);
      Shuffle (A2, S2);

      S3 := 9_999;
      A3 := Copy_Of (Base);
      Shuffle (A3, S3);

      if not Same (A1, A2) then
         Differ_Count := Differ_Count + 1;
      end if;
      if not Same (A1, A3) then
         Differ_Count := Differ_Count + 1;
      end if;
      if not Same (A2, A3) then
         Differ_Count := Differ_Count + 1;
      end if;

      Check (Differ_Count >= 2,
             "different seeds usually produce different perms");
      Check (Is_Permutation_Of (A1, Base), "seed1 result is perm");
      Check (Is_Permutation_Of (A2, Base), "seed2 result is perm");
      Check (Is_Permutation_Of (A3, Base), "seed3 result is perm");
   end;

   ---------------------------------------------------------------------
   Section ("5. Access-to-function Shuffle");
   ---------------------------------------------------------------------
   declare
      Base : constant Element_Array := [1, 2, 3, 4, 5, 6, 7, 8];
      A    : Element_Array := Copy_Of (Base);
      B    : Element_Array := Copy_Of (Base);
   begin
      Test_RNG.Inject_Seed := 777;
      A := Copy_Of (Base);
      Shuffle (A, Test_RNG.Injected_Next'Access);
      Check (Is_Permutation_Of (A, Base), "injected RNG preserves multiset");

      Test_RNG.Inject_Seed := 777;
      B := Copy_Of (Base);
      Shuffle (B, Test_RNG.Injected_Next'Access);
      Check (Same (A, B), "same inject seed → identical");

      A := Copy_Of (Base);
      Shuffle (A, Test_RNG.Always_Hi'Access);
      Check (Same (A, Base), "Always_Hi → identity permutation");

      A := Copy_Of (Base);
      Shuffle (A, Test_RNG.Always_Lo'Access);
      Check (Is_Permutation_Of (A, Base), "Always_Lo still a perm");
      Check (not Same (A, Base), "Always_Lo changes order for n>1");
   end;

   ---------------------------------------------------------------------
   Section ("6. Invalid_Argument");
   ---------------------------------------------------------------------
   declare
      function LCG_Raises return Boolean is
         A    : Element_Array (1 .. Max_N + 1) := [others => 0];
         Seed : Unsigned_64 := 1;
      begin
         Shuffle (A, Seed);
         return False;
      exception
         when Invalid_Argument =>
            return True;
      end LCG_Raises;

      function Access_Raises_Null return Boolean is
         A : Element_Array := [1, 2, 3];
      begin
         Shuffle (A, null);
         return False;
      exception
         when Invalid_Argument =>
            return True;
      end Access_Raises_Null;

      function Access_Raises_OOR return Boolean is
         A : Element_Array := [1, 2, 3, 4];
      begin
         Shuffle (A, Test_RNG.Out_Of_Range'Access);
         return False;
      exception
         when Invalid_Argument =>
            return True;
      end Access_Raises_OOR;

      function Access_Raises_Len return Boolean is
         A : Element_Array (1 .. Max_N + 1) := [others => 1];
      begin
         Shuffle (A, Test_RNG.Always_Hi'Access);
         return False;
      exception
         when Invalid_Argument =>
            return True;
      end Access_Raises_Len;
   begin
      Check (LCG_Raises, "LCG Shuffle raises on Length > Max_N");
      Check (Access_Raises_Null, "access Shuffle raises on null Next");
      Check (Access_Raises_OOR, "access Shuffle raises on OOR index");
      Check (Access_Raises_Len, "access Shuffle raises on Length > Max_N");
   end;

   ---------------------------------------------------------------------
   Section ("7. Is_Permutation_Of helper");
   ---------------------------------------------------------------------
   Check (Is_Permutation_Of ([1, 2, 3], [3, 2, 1]), "123 ~ 321");
   Check (Is_Permutation_Of ([1, 1, 2], [2, 1, 1]), "112 ~ 211");
   Check (not Is_Permutation_Of ([1, 2, 3], [1, 2, 4]), "123 !~ 124");
   Check (not Is_Permutation_Of ([1, 2], [1, 2, 3]), "length mismatch");
   Check (Is_Permutation_Of ([1 => 5], [1 => 5]), "singleton match");
   Check (not Is_Permutation_Of ([1 => 5], [1 => 6]), "singleton mismatch");
   declare
      E1 : Element_Array (1 .. 0);
      E2 : Element_Array (5 .. 4);
   begin
      Check (Is_Permutation_Of (E1, E2), "two empties match");
   end;
   Check (Is_Permutation_Of ([-1, -1, 0], [0, -1, -1]), "neg multiset");

   ---------------------------------------------------------------------
   Section ("8. Two-element coverage across seeds");
   ---------------------------------------------------------------------
   declare
      Seed : Unsigned_64;
      Seen_Swap : Boolean := False;
      Seen_Keep : Boolean := False;
      All_Perm  : Boolean := True;
   begin
      for S in Unsigned_64 range 1 .. 32 loop
         declare
            A : Element_Array := [10, 20];
         begin
            Seed := S;
            Shuffle (A, Seed);
            if not Is_Permutation_Of (A, [10, 20]) then
               All_Perm := False;
            end if;
            if A (1) = 20 then
               Seen_Swap := True;
            else
               Seen_Keep := True;
            end if;
         end;
      end loop;
      Check (All_Perm, "all 32 pair shuffles are permutations");
      Check (Seen_Swap, "pair: observed swapped order");
      Check (Seen_Keep, "pair: observed identity order");

      --  Three-element: several seeds, each a perm.
      for S in Unsigned_64 range 1 .. 16 loop
         declare
            A : Element_Array := [1, 2, 3];
         begin
            Seed := S * 17;
            Shuffle (A, Seed);
            Check (Is_Permutation_Of (A, [1, 2, 3]),
                   "triple seed" & Unsigned_64'Image (S) & " is perm");
         end;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("9. Larger array + continued seed stream");
   ---------------------------------------------------------------------
   declare
      Seed : Unsigned_64 := 2026;
      A    : Element_Array (1 .. 64);
      Orig : Element_Array (1 .. 64);
      B    : Element_Array (1 .. 64);
   begin
      for I in A'Range loop
         A (I) := I * 3 - 7;
         Orig (I) := A (I);
      end loop;
      Shuffle (A, Seed);
      Check (Is_Permutation_Of (A, Orig), "n=64 first shuffle is perm");
      Check (not Same (A, Orig), "n=64 usually not identity");

      B := Copy_Of (Orig);
      Shuffle (B, Seed);
      Check (Is_Permutation_Of (B, Orig), "n=64 continued stream is perm");
      Check (not Same (A, B), "continued seed stream differs");
   end;

   ---------------------------------------------------------------------
   Section ("10. Modest large n accepted");
   ---------------------------------------------------------------------
   declare
      A    : Element_Array (1 .. 1_000);
      Seed : Unsigned_64 := 11;
      Ok   : Boolean := True;
      Orig : Element_Array (1 .. 1_000);
   begin
      for I in A'Range loop
         A (I) := I;
         Orig (I) := I;
      end loop;
      begin
         Shuffle (A, Seed);
      exception
         when Invalid_Argument =>
            Ok := False;
      end;
      Check (Ok, "n=1000 accepted (< Max_N)");
      Check (Is_Permutation_Of (A, Orig), "n=1000 is permutation");
   end;

   ---------------------------------------------------------------------
   New_Line;
   Put_Line ("Results: "
             & Natural'Image (Pass_Count) & " PASS,"
             & Natural'Image (Fail_Count) & " FAIL");
   if Fail_Count /= 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
