--  Standalone test suite for K_Way_Merge (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with K_Way_Merge; use K_Way_Merge;

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

   function Same (A, B : Vector) return Boolean is
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

   procedure Reference_Sort (A : in out Vector) is
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

   function Concat (Lists : Vector_List) return Vector is
      Total : Natural := 0;
   begin
      for L of Lists loop
         if L /= null then
            Total := Total + L'Length;
         end if;
      end loop;
      declare
         C : Vector (1 .. Total);
         P : Natural := 1;
      begin
         for L of Lists loop
            if L /= null then
               for X of L.all loop
                  C (P) := X;
                  P := P + 1;
               end loop;
            end if;
         end loop;
         return C;
      end;
   end Concat;

   function New_V (A : Vector) return Vector_Access is
   begin
      return new Vector'(A);
   end New_V;

   function Merge_Raises (Lists : Vector_List) return Boolean is
   begin
      declare
         R : constant Vector := Merge (Lists);
         pragma Unreferenced (R);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Merge_Raises;

   function Merge2_Raises (A, B : Vector) return Boolean is
   begin
      declare
         R : constant Vector := Merge (A, B);
         pragma Unreferenced (R);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Merge2_Raises;

   procedure Expect_Merge
     (Lists : Vector_List;
      Label : String)
   is
      Got : constant Vector := Merge (Lists);
      Ref : Vector := Concat (Lists);
   begin
      Reference_Sort (Ref);
      Check (Is_Sorted (Got), Label & " Is_Sorted");
      Check (Same (Got, Ref), Label & " matches sort(concat)");
      Check (Got'Length = Ref'Length, Label & " length");
   end Expect_Merge;

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

   function Sorted_Random (Len : Natural; Lo, Hi : Integer) return Vector is
      Span : constant Positive := Hi - Lo + 1;
      A    : Vector (1 .. Len);
   begin
      for I in A'Range loop
         A (I) := Lo + Integer (Next_Mod (Span));
      end loop;
      Reference_Sort (A);
      return A;
   end Sorted_Random;

begin
   ---------------------------------------------------------------------
   Section ("1. Is_Sorted");
   ---------------------------------------------------------------------
   declare
      Empty : constant Vector (1 .. 0) := [];
      One   : constant Vector := [42];
      Asc   : constant Vector := [1, 2, 3, 4];
      Dup   : constant Vector := [2, 2, 2];
      Bad   : constant Vector := [1, 3, 2];
      Rev   : constant Vector := [5, 4, 3];
   begin
      Check (Is_Sorted (Empty), "empty Is_Sorted");
      Check (Is_Sorted (One), "singleton Is_Sorted");
      Check (Is_Sorted (Asc), "ascending Is_Sorted");
      Check (Is_Sorted (Dup), "duplicates Is_Sorted");
      Check (not Is_Sorted (Bad), "unsorted rejected");
      Check (not Is_Sorted (Rev), "reverse rejected");
   end;

   ---------------------------------------------------------------------
   Section ("2. k = 0 / empty lists");
   ---------------------------------------------------------------------
   declare
      None       : constant Vector_List (1 .. 0) := [];
      E1         : constant Vector_Access := New_V ([]);
      E2         : constant Vector_Access := New_V ([]);
      Only_Empty : constant Vector_List := [E1, E2];
      Mixed_Null : constant Vector_List := [null, E1, null];
      R0         : constant Vector := Merge (None);
      R1         : constant Vector := Merge (Only_Empty);
      R2         : constant Vector := Merge (Mixed_Null);
   begin
      Check (R0'Length = 0, "k=0 empty result");
      Check (Is_Sorted (R0), "k=0 Is_Sorted");
      Check (R1'Length = 0, "all-empty lists length 0");
      Check (R2'Length = 0, "null+empty length 0");
   end;

   ---------------------------------------------------------------------
   Section ("3. k = 1");
   ---------------------------------------------------------------------
   declare
      A  : constant Vector_Access := New_V ([1, 3, 5, 7, 9]);
      B  : constant Vector_Access := New_V ([42]);
      C  : constant Vector_Access := New_V ([0, 0, 0]);
   begin
      Expect_Merge ([A], "k=1 classic odds");
      Expect_Merge ([B], "k=1 singleton");
      Expect_Merge ([C], "k=1 all equal");
   end;

   ---------------------------------------------------------------------
   Section ("4. k = 2 classic");
   ---------------------------------------------------------------------
   declare
      A : constant Vector_Access := New_V ([1, 3, 5]);
      B : constant Vector_Access := New_V ([2, 4, 6]);
      C : constant Vector_Access := New_V ([1, 2, 3]);
      D : constant Vector_Access := New_V ([4, 5, 6]);
      E : constant Vector_Access := New_V ([]);
      F : constant Vector_Access := New_V ([10, 20]);
      G : constant Vector_Access := New_V ([-5, -1, 0]);
      H : constant Vector_Access := New_V ([-3, 2, 8]);
   begin
      Expect_Merge ([A, B], "k=2 odds+evens");
      Expect_Merge ([C, D], "k=2 contiguous ranges");
      Expect_Merge ([E, F], "k=2 empty+nonempty");
      Expect_Merge ([F, E], "k=2 nonempty+empty");
      Expect_Merge ([G, H], "k=2 negatives");
      declare
         M : constant Vector := Merge (A.all, B.all);
      begin
         Check (Same (M, [1, 2, 3, 4, 5, 6]), "2-way function odds+evens");
         Check (Is_Sorted (M), "2-way function Is_Sorted");
      end;
      declare
         Buf  : Vector (1 .. 6);
         Last : Natural;
      begin
         Merge (A.all, B.all, Buf, Last);
         Check (Last = 6, "2-way procedure Last");
         Check (Same (Buf (1 .. Last), [1, 2, 3, 4, 5, 6]),
                "2-way procedure values");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("5. k = 3 classic");
   ---------------------------------------------------------------------
   declare
      A : constant Vector_Access := New_V ([1, 4, 7]);
      B : constant Vector_Access := New_V ([2, 5, 8]);
      C : constant Vector_Access := New_V ([3, 6, 9]);
      D : constant Vector_Access := New_V ([1, 1, 1]);
      E : constant Vector_Access := New_V ([1, 1]);
      F : constant Vector_Access := New_V ([1]);
   begin
      Expect_Merge ([A, B, C], "k=3 round-robin");
      Expect_Merge ([C, A, B], "k=3 reordered inputs");
      Expect_Merge ([D, E, F], "k=3 all equal ones");
   end;

   ---------------------------------------------------------------------
   Section ("6. All equal / duplicates across lists");
   ---------------------------------------------------------------------
   declare
      A : constant Vector_Access := New_V ([5, 5, 5]);
      B : constant Vector_Access := New_V ([5, 5]);
      C : constant Vector_Access := New_V ([5, 5, 5, 5]);
   begin
      Expect_Merge ([A, B, C], "all fives across 3 lists");
   end;

   ---------------------------------------------------------------------
   Section ("7. Larger k and vs sort(concat)");
   ---------------------------------------------------------------------
   declare
      Vals  : array (1 .. 8) of Vector_Access;
      Lists : Vector_List (1 .. 8);
   begin
      for I in Vals'Range loop
         Vals (I) := New_V (Sorted_Random (20, -50, 50));
         Lists (I) := Vals (I);
      end loop;
      Expect_Merge (Lists, "k=8 random sorted runs");
   end;

   declare
      Vals  : array (1 .. 16) of Vector_Access;
      Lists : Vector_List (1 .. 16);
   begin
      for I in Vals'Range loop
         Vals (I) := New_V (Sorted_Random (10, 0, 100));
         Lists (I) := Vals (I);
      end loop;
      Expect_Merge (Lists, "k=16 random sorted runs");
   end;

   ---------------------------------------------------------------------
   Section ("8. Single-element lists (heap of k heads)");
   ---------------------------------------------------------------------
   declare
      Vals  : array (1 .. 10) of Vector_Access;
      Lists : Vector_List (1 .. 10);
   begin
      for I in Vals'Range loop
         Vals (I) := New_V ([11 - I]);
         Lists (I) := Vals (I);
      end loop;
      Expect_Merge (Lists, "k=10 singletons reverse");
   end;

   ---------------------------------------------------------------------
   Section ("9. Invalid_Argument");
   ---------------------------------------------------------------------
   declare
      Bad      : constant Vector_Access := New_V ([3, 1, 2]);
      Good     : constant Vector_Access := New_V ([1, 2, 3]);
      Too_Many : constant Vector_List (1 .. Max_K + 1) := [others => null];
   begin
      Check (Merge_Raises ([Bad]), "unsorted single list raises");
      Check (Merge_Raises ([Good, Bad]), "unsorted among k raises");
      Check (Merge2_Raises ([1, 0], [2, 3]), "2-way unsorted A raises");
      Check (Merge2_Raises ([1, 2], [4, 3]), "2-way unsorted B raises");
      Check (Merge_Raises (Too_Many), "k > Max_K raises");

      declare
         Buf    : Vector (1 .. 2);
         Last   : Natural;
         Raised : Boolean := False;
      begin
         begin
            Merge ([1, 2, 3], [4, 5], Buf, Last);
         exception
            when Invalid_Argument =>
               Raised := True;
         end;
         Check (Raised, "2-way short Output raises");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("10. Edge values");
   ---------------------------------------------------------------------
   declare
      A : constant Vector_Access :=
        New_V ([Integer'First, Integer'First + 1]);
      B : constant Vector_Access :=
        New_V ([Integer'Last - 1, Integer'Last]);
      C : constant Vector_Access := New_V ([-1, 0, 1]);
   begin
      Expect_Merge ([A, B], "extreme Integer ends");
      Expect_Merge ([C, A, B], "extremes + center");
   end;

   ---------------------------------------------------------------------
   Section ("11. Interleaved lengths");
   ---------------------------------------------------------------------
   declare
      Long_L : constant Vector_Access :=
        New_V (Sorted_Random (100, -1000, 1000));
      Short  : constant Vector_Access := New_V ([0]);
      Mid    : constant Vector_Access :=
        New_V (Sorted_Random (25, -100, 100));
   begin
      Expect_Merge ([Long_L, Short, Mid], "long+short+mid");
      Expect_Merge ([Short, Short, Long_L], "two shorts + long");
   end;

   ---------------------------------------------------------------------
   Section ("12. Partitioned ranges / idempotent k=1");
   ---------------------------------------------------------------------
   declare
      A : constant Vector_Access := New_V ([1, 2, 3]);
      B : constant Vector_Access := New_V ([4, 5, 6]);
      C : constant Vector_Access := New_V ([7, 8, 9]);
      M : constant Vector := Merge ([A, B, C]);
   begin
      Check (Same (M, [1, 2, 3, 4, 5, 6, 7, 8, 9]), "partitioned ranges");
      Check (Is_Sorted (M), "partitioned Is_Sorted");
      declare
         R  : constant Vector_Access := New_V (M);
         M2 : constant Vector := Merge ([R]);
      begin
         Check (Same (M2, M), "k=1 of prior merge");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("13. 2-way empty sides");
   ---------------------------------------------------------------------
   declare
      Empty : constant Vector (1 .. 0) := [];
      One   : constant Vector := [7];
      M1    : constant Vector := Merge (Empty, One);
      M2    : constant Vector := Merge (One, Empty);
      M3    : constant Vector := Merge (Empty, Empty);
   begin
      Check (Same (M1, [7]), "2-way empty+one");
      Check (Same (M2, [7]), "2-way one+empty");
      Check (M3'Length = 0, "2-way empty+empty");
   end;

   ---------------------------------------------------------------------
   Section ("14. More classic patterns");
   ---------------------------------------------------------------------
   declare
      A : constant Vector_Access := New_V ([1, 1, 2, 3]);
      B : constant Vector_Access := New_V ([1, 2, 2, 4]);
      C : constant Vector_Access := New_V ([0, 5]);
      D : constant Vector_Access := New_V ([10]);
      E : constant Vector_Access := New_V ([1, 10, 100, 1000]);
      F : constant Vector_Access := New_V ([2, 20, 200]);
      G : constant Vector_Access := New_V ([3, 30]);
   begin
      Expect_Merge ([A, B], "multisets overlap");
      Expect_Merge ([C, D], "small+singleton");
      Expect_Merge ([E, F, G], "powers-ish three-way");
   end;

   New_Line;
   Put_Line ("Results:" & Pass_Count'Image & " PASS,"
             & Fail_Count'Image & " FAIL");
   if Fail_Count > 0 then
      raise Program_Error with "test failures present";
   end if;
end Tests;
