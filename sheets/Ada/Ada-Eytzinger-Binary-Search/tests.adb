--  Standalone test suite for Eytzinger_Binary_Search (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Eytzinger_Binary_Search; use Eytzinger_Binary_Search;

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
         Ada.Text_IO.Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Ada.Text_IO.Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      Ada.Text_IO.New_Line;
      Ada.Text_IO.Put_Line ("=== " & Title & " ===");
   end Section;

   --  Non-static views (avoid -gnatwa constant-condition warnings).
   function I (X : Integer) return Integer is (X);

   function Sentinel (A : Element_Array) return Integer is
     (Integer (A'First) - 1);

   function Copy_Of (A : Element_Array) return Element_Array is
   begin
      return Element_Array'(A);
   end Copy_Of;

   procedure Insertion_Sort (A : in out Element_Array) is
   begin
      if A'Length <= 1 then
         return;
      end if;
      for Idx in A'First + 1 .. A'Last loop
         declare
            Key : constant Integer := A (Idx);
            J   : Integer := Integer (Idx) - 1;
         begin
            while J >= Integer (A'First) and then A (J) > Key loop
               A (J + 1) := A (J);
               J := J - 1;
            end loop;
            A (J + 1) := Key;
         end;
      end loop;
   end Insertion_Sort;

   function Same_Multiset (A, B : Element_Array) return Boolean is
      X : Element_Array := Copy_Of (A);
      Y : Element_Array := Copy_Of (B);
   begin
      if X'Length /= Y'Length then
         return False;
      end if;
      Insertion_Sort (X);
      Insertion_Sort (Y);
      for K in X'Range loop
         if X (K) /= Y (K - X'First + Y'First) then
            return False;
         end if;
      end loop;
      return True;
   end Same_Multiset;

   function Same_Values (A, B : Element_Array) return Boolean is
   begin
      if A'Length /= B'Length then
         return False;
      end if;
      for K in A'Range loop
         if A (K) /= B (K - A'First + B'First) then
            return False;
         end if;
      end loop;
      return True;
   end Same_Values;

   procedure Expect_Build_Preserves
     (Sorted : Element_Array; Label : String)
   is
      Layout : Element_Array (Sorted'Range);
   begin
      Build (Sorted, Layout);
      Check (Same_Multiset (Sorted, Layout),
             Label & " Build preserves multiset");
   end Expect_Build_Preserves;

   procedure Expect_Hit
     (Sorted : Element_Array;
      Key    : Integer;
      Label  : String)
   is
      Layout : Element_Array (Sorted'Range);
      F      : Integer;
      C      : Integer;
   begin
      Build (Sorted, Layout);
      F := Find (Layout, Key);
      C := Classic_Binary_Search (Sorted, Key);
      Check (C >= Integer (Sorted'First)
             and then C <= Integer (Sorted'Last),
             Label & " classic hit in range");
      Check (F >= Integer (Layout'First)
             and then F <= Integer (Layout'Last),
             Label & " eytzinger hit in range");
      if F >= Integer (Layout'First)
        and then F <= Integer (Layout'Last)
      then
         Check (Layout (Natural (F)) = Key,
                Label & " eytzinger value");
      else
         Check (False, Label & " eytzinger value (skipped)");
      end if;
   end Expect_Hit;

   procedure Expect_Miss
     (Sorted : Element_Array;
      Key    : Integer;
      Label  : String)
   is
      Layout : Element_Array (Sorted'Range);
      F      : Integer;
      C      : Integer;
   begin
      Build (Sorted, Layout);
      F := Find (Layout, Key);
      C := Classic_Binary_Search (Sorted, Key);
      Check (C = Sentinel (Sorted), Label & " classic miss");
      Check (F = Sentinel (Layout), Label & " eytzinger miss");
   end Expect_Miss;

   procedure Expect_Roundtrip_Sorted_Index
     (Sorted : Element_Array; Label : String)
   is
      Layout : Element_Array (Sorted'Range);
      SI     : Integer;
   begin
      Build (Sorted, Layout);
      for Off in 0 .. Integer (Sorted'Length) - 1 loop
         declare
            Lix : constant Natural := Layout'First + Natural (Off);
         begin
            SI := Sorted_Index (Lix, Sorted'Length, Layout'First);
            Check (SI >= Integer (Sorted'First)
                   and then SI <= Integer (Sorted'Last),
                   Label & " SI range off=" & Natural'Image (Natural (Off)));
            if SI >= Integer (Sorted'First)
              and then SI <= Integer (Sorted'Last)
            then
               Check (Sorted (Natural (SI)) = Layout (Lix),
                      Label & " SI value off="
                      & Natural'Image (Natural (Off)));
            end if;
         end;
      end loop;
   end Expect_Roundtrip_Sorted_Index;

   function Build_Raises
     (Sorted : Element_Array; Layout_Len : Natural) return Boolean
   is
      Layout : Element_Array (1 .. Layout_Len);
   begin
      Build (Sorted, Layout);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Build_Raises;

   --  Deterministic LCG.
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

   ------------------------------------------------------------------
   -- Fixtures
   ------------------------------------------------------------------

   Empty_1 : Element_Array (1 .. 0);

   Single   : constant Element_Array (0 .. 0) := [0 => 42];
   Single_1 : constant Element_Array (1 .. 1) := [1 => 7];

   Two   : constant Element_Array (0 .. 1) := [10, 20];
   Three : constant Element_Array (0 .. 2) := [1, 2, 3];

   Perfect : constant Element_Array (0 .. 6) :=
     [1, 2, 3, 4, 5, 6, 7];
   Perfect_Layout_Expected : constant Element_Array (0 .. 6) :=
     [4, 2, 6, 1, 3, 5, 7];

   Five : constant Element_Array (0 .. 4) :=
     [10, 20, 30, 40, 50];
   Five_Layout_Expected : constant Element_Array (0 .. 4) :=
     [40, 20, 50, 10, 30];

   Wiki : constant Element_Array (0 .. 9) :=
     [1, 3, 5, 6, 7, 9, 14, 15, 17, 19];

   Dup : constant Element_Array (0 .. 5) := [1, 2, 2, 2, 3, 4];
   Neg : constant Element_Array (0 .. 4) := [-10, -3, 0, 5, 12];
   Ones : constant Element_Array (5 .. 9) :=
     [5 => 1, 6 => 1, 7 => 1, 8 => 1, 9 => 1];

   Pow2  : constant Element_Array (0 .. 7) :=
     [1, 2, 3, 4, 5, 6, 7, 8];
   Odd_N : constant Element_Array (0 .. 6) :=
     [2, 4, 6, 8, 10, 12, 14];

   Based1 : constant Element_Array (1 .. 5) :=
     [1 => 11, 2 => 22, 3 => 33, 4 => 44, 5 => 55];

begin
   Ada.Text_IO.Put_Line ("Eytzinger_Binary_Search tests");
   Ada.Text_IO.Put_Line ("==============================");

   ------------------------------------------------------------------
   Section ("1. Empty / singleton");
   ------------------------------------------------------------------
   declare
      E      : Element_Array renames Empty_1;
      Layout : Element_Array (1 .. 0);
   begin
      Check (E'Length = 0, "empty length 0");
      Build (E, Layout);
      Check (Find (Layout, I (1)) = Sentinel (Layout), "empty find miss");
      Check (Classic_Binary_Search (E, I (1)) = Sentinel (E),
             "empty classic miss");
      Check (Is_Sorted_Ascending (E), "empty is sorted");
   end;

   declare
      Layout : Element_Array (Single'Range);
   begin
      Build (Single, Layout);
      Check (Layout (0) = 42, "singleton layout value");
      Check (Find (Layout, 42) = 0, "singleton hit index");
      Check (Find (Layout, 0) = Sentinel (Layout), "singleton miss low");
      Check (Find (Layout, 100) = Sentinel (Layout), "singleton miss high");
   end;

   declare
      Layout : Element_Array (Single_1'Range);
   begin
      Build (Single_1, Layout);
      Check (Find (Layout, 7) = 1, "singleton 1-based hit");
      Check (Find (Layout, 6) = Sentinel (Layout), "singleton 1-based miss");
      Check (Sorted_Index (1, 1, 1) = 1, "singleton Sorted_Index");
   end;

   ------------------------------------------------------------------
   Section ("2. Known layouts (perfect & n=5)");
   ------------------------------------------------------------------
   declare
      Layout : Element_Array (Perfect'Range);
   begin
      Build (Perfect, Layout);
      Check (Same_Values (Layout, Perfect_Layout_Expected),
             "n=7 perfect layout [4,2,6,1,3,5,7]");
      Check (Find (Layout, 4) = 0, "perfect find 4 at root");
      Check (Find (Layout, 1) = 3, "perfect find 1");
      Check (Find (Layout, 7) = 6, "perfect find 7");
      Check (Find (Layout, 5) = 5, "perfect find 5");
      Check (Find (Layout, 0) = Sentinel (Layout), "perfect miss 0");
      Check (Find (Layout, 8) = Sentinel (Layout), "perfect miss 8");
   end;

   declare
      Layout : Element_Array (Five'Range);
   begin
      Build (Five, Layout);
      Check (Same_Values (Layout, Five_Layout_Expected),
             "n=5 layout [40,20,50,10,30]");
      Check (Find (Layout, 40) = 0, "five find 40");
      Check (Find (Layout, 10) = 3, "five find 10");
      Check (Find (Layout, 30) = 4, "five find 30");
      Check (Find (Layout, 25) = Sentinel (Layout), "five miss 25");
   end;

   ------------------------------------------------------------------
   Section ("3. Build preserves multiset");
   ------------------------------------------------------------------
   Expect_Build_Preserves (Two, "two");
   Expect_Build_Preserves (Three, "three");
   Expect_Build_Preserves (Perfect, "perfect");
   Expect_Build_Preserves (Five, "five");
   Expect_Build_Preserves (Wiki, "wiki");
   Expect_Build_Preserves (Dup, "dup");
   Expect_Build_Preserves (Neg, "neg");
   Expect_Build_Preserves (Ones, "ones");
   Expect_Build_Preserves (Pow2, "pow2");
   Expect_Build_Preserves (Odd_N, "odd_n");
   Expect_Build_Preserves (Based1, "1-based");

   ------------------------------------------------------------------
   Section ("4. Hits match classic presence");
   ------------------------------------------------------------------
   Expect_Hit (Two, 10, "two 10");
   Expect_Hit (Two, 20, "two 20");
   Expect_Hit (Three, 1, "three 1");
   Expect_Hit (Three, 2, "three 2");
   Expect_Hit (Three, 3, "three 3");
   Expect_Hit (Wiki, 1, "wiki 1");
   Expect_Hit (Wiki, 7, "wiki 7");
   Expect_Hit (Wiki, 19, "wiki 19");
   Expect_Hit (Wiki, 14, "wiki 14");
   Expect_Hit (Neg, -10, "neg -10");
   Expect_Hit (Neg, 0, "neg 0");
   Expect_Hit (Neg, 12, "neg 12");
   Expect_Hit (Dup, 2, "dup 2");
   Expect_Hit (Ones, 1, "ones 1");
   Expect_Hit (Based1, 33, "based1 33");
   Expect_Hit (Based1, 11, "based1 11");
   Expect_Hit (Based1, 55, "based1 55");
   Expect_Hit (Pow2, 8, "pow2 8");
   Expect_Hit (Odd_N, 8, "odd_n 8");

   ------------------------------------------------------------------
   Section ("5. Misses match classic presence");
   ------------------------------------------------------------------
   Expect_Miss (Two, 15, "two 15");
   Expect_Miss (Two, 0, "two 0");
   Expect_Miss (Two, 100, "two 100");
   Expect_Miss (Three, 0, "three 0");
   Expect_Miss (Three, 4, "three 4");
   Expect_Miss (Wiki, 2, "wiki 2");
   Expect_Miss (Wiki, 8, "wiki 8");
   Expect_Miss (Wiki, 100, "wiki 100");
   Expect_Miss (Neg, -11, "neg -11");
   Expect_Miss (Neg, 1, "neg 1");
   Expect_Miss (Dup, 0, "dup 0");
   Expect_Miss (Dup, 5, "dup 5");
   Expect_Miss (Based1, 12, "based1 12");
   Expect_Miss (Pow2, 0, "pow2 0");
   Expect_Miss (Odd_N, 7, "odd_n 7");

   ------------------------------------------------------------------
   Section ("6. Sorted_Index round-trip");
   ------------------------------------------------------------------
   Expect_Roundtrip_Sorted_Index (Three, "three");
   Expect_Roundtrip_Sorted_Index (Five, "five");
   Expect_Roundtrip_Sorted_Index (Based1, "based1");

   Check (Sorted_Index (0, 7, 0) = 3, "perfect SI root → sorted idx 3");
   Check (Sorted_Index (3, 7, 0) = 0, "perfect SI layout[3] → 0");
   Check (Sorted_Index (6, 7, 0) = 6, "perfect SI layout[6] → 6");

   ------------------------------------------------------------------
   Section ("7. Invalid_Argument");
   ------------------------------------------------------------------
   declare
      S : constant Element_Array (1 .. 3) := [1, 2, 3];
   begin
      Check (Build_Raises (S, 2), "Build length mismatch raises");
      Check (Build_Raises (S, 4), "Build longer layout raises");
   end;

   declare
      function SI_Raises (Layout_Index, Length, First : Natural) return Boolean is
         Unused : Integer;
      begin
         Unused := Sorted_Index (Layout_Index, Length, First);
         if Unused = I (Integer'First) then
            return False;
         end if;
         return False;
      exception
         when Invalid_Argument =>
            return True;
      end SI_Raises;
   begin
      Check (SI_Raises (0, 0, 0), "Sorted_Index empty raises");
      Check (SI_Raises (99, 5, 0), "Sorted_Index OOB raises");
   end;

   ------------------------------------------------------------------
   Section ("8. Random array vs classic presence");
   ------------------------------------------------------------------
   declare
      N      : constant := 32;
      Sorted : Element_Array (0 .. N - 1);
      Layout : Element_Array (0 .. N - 1);
      V      : Integer := -50;
      Hits   : Natural := 0;
      Misses : Natural := 0;
      F, C   : Integer;
   begin
      for K in Sorted'Range loop
         V := V + Integer (Next_Mod (5)) + 1;
         Sorted (K) := V;
      end loop;
      Check (Is_Sorted_Ascending (Sorted), "random sorted");
      Build (Sorted, Layout);
      Check (Same_Multiset (Sorted, Layout), "random multiset");

      for K in Sorted'Range loop
         F := Find (Layout, Sorted (K));
         C := Classic_Binary_Search (Sorted, Sorted (K));
         if F >= Integer (Layout'First)
           and then F <= Integer (Layout'Last)
           and then Layout (Natural (F)) = Sorted (K)
           and then C >= Integer (Sorted'First)
         then
            Hits := Hits + 1;
         end if;
      end loop;
      Check (Hits = N, "random all keys found");

      F := Find (Layout, Sorted (Sorted'First) - 1);
      C := Classic_Binary_Search (Sorted, Sorted (Sorted'First) - 1);
      if F = Sentinel (Layout) and then C = Sentinel (Sorted) then
         Misses := Misses + 1;
      end if;
      F := Find (Layout, Sorted (Sorted'Last) + 1);
      C := Classic_Binary_Search (Sorted, Sorted (Sorted'Last) + 1);
      if F = Sentinel (Layout) and then C = Sentinel (Sorted) then
         Misses := Misses + 1;
      end if;
      F := Find (Layout, Sorted (N / 2) + 1);
      C := Classic_Binary_Search (Sorted, Sorted (N / 2) + 1);
      --  gap may or may not exist; only count when classic also misses
      if C = Sentinel (Sorted) and then F = Sentinel (Layout) then
         Misses := Misses + 1;
      elsif C /= Sentinel (Sorted)
        and then F >= Integer (Layout'First)
        and then Layout (Natural (F)) = Sorted (N / 2) + 1
      then
         Misses := Misses + 1;  -- both hit the same present value
      end if;
      Check (Misses = 3, "random boundary/gap agree with classic");
   end;

   ------------------------------------------------------------------
   Section ("9. Is_Sorted_Ascending");
   ------------------------------------------------------------------
   Check (Is_Sorted_Ascending (Wiki), "wiki sorted");
   Check (Is_Sorted_Ascending (Single), "single sorted");
   declare
      Bad : constant Element_Array (0 .. 2) := [3, 1, 2];
   begin
      Check (not Is_Sorted_Ascending (Bad), "unsorted detected");
   end;

   ------------------------------------------------------------------
   -- Summary
   ------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Results: " & Natural'Image (Pass_Count) & " PASS,"
      & Natural'Image (Fail_Count) & " FAIL");

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
