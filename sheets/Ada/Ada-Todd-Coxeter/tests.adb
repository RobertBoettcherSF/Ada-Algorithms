--  Standalone test suite for Todd_Coxeter (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Todd_Coxeter; use Todd_Coxeter;

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

   function W (S : String) return Word is (Make_Word (S));

   function Empty_Subgroup return Word_List is
      E : Word_List (1 .. 0);
   begin
      return E;
   end Empty_Subgroup;

   function One (S : String) return Word_List is ([W (S)]);

   function Two (A, B : String) return Word_List is ([W (A), W (B)]);

   function Three (A, B, C : String) return Word_List is
     ([W (A), W (B), W (C)]);

   function Expect_Index
     (Pres     : Presentation;
      Subgroup : Word_List;
      Limit    : Positive;
      Want     : Natural) return Boolean
   is
      R : constant Result := Enumerate (Pres, Subgroup, Limit);
   begin
      return R.Success and then R.Index = Want;
   end Expect_Index;

   function Expect_Fail
     (Pres     : Presentation;
      Subgroup : Word_List;
      Limit    : Positive) return Boolean
   is
      R : constant Result := Enumerate (Pres, Subgroup, Limit);
   begin
      return not R.Success;
   end Expect_Fail;

   ------------------------------------------------------------------
   --  Cyclic groups C_n = <a | a^n>
   ------------------------------------------------------------------

   function Cyclic (N : Positive) return Presentation is
      Pow : String (1 .. N);
      Rels : Word_List (1 .. 1);
   begin
      for I in 1 .. N loop
         Pow (I) := 'a';
      end loop;
      Rels (1) := W (Pow);
      return Make_Presentation ("a", Rels);
   end Cyclic;

   ------------------------------------------------------------------
   --  Classic presentations
   ------------------------------------------------------------------

   --  S3 = <a,b | a^2, b^3, (ab)^2>
   function S3 return Presentation is
     (Make_Presentation ("ab", Three ("aa", "bbb", "abab")));

   --  A4 = <a,b | a^2, b^3, (ab)^3>
   function A4 return Presentation is
     (Make_Presentation ("ab", Three ("aa", "bbb", "ababab")));

   --  V4 Klein = <a,b | a^2, b^2, (ab)^2>
   function V4 return Presentation is
     (Make_Presentation ("ab", Three ("aa", "bb", "abab")));

   --  D4 dihedral of order 8 = <a,b | a^4, b^2, (ab)^2>
   function D4 return Presentation is
     (Make_Presentation ("ab", Three ("aaaa", "bb", "abab")));

   --  D5 dihedral of order 10 = <a,b | a^5, b^2, (ab)^2>
   function D5 return Presentation is
     (Make_Presentation ("ab", Three ("aaaaa", "bb", "abab")));

   --  D6 dihedral of order 12 = <a,b | a^6, b^2, (ab)^2>
   function D6 return Presentation is
     (Make_Presentation ("ab", Three ("aaaaaa", "bb", "abab")));

   --  Q8 = <a,b | a^4, a^2 b^{-2}, b^{-1} a b a>
   function Q8 return Presentation is
     (Make_Presentation ("ab", Three ("aaaa", "aaBB", "Baba")));

   --  C2 x C2 already V4; C2 = <a | a^2>
   function C2 return Presentation is (Cyclic (2));

   --  Trivial: <a | a>
   function Trivial_A return Presentation is
     (Make_Presentation ("a", One ("a")));

   --  Free product-ish infinite: <a,b | > no relators — will not close
   function Free_AB return Presentation is
      Empty : Word_List (1 .. 0);
   begin
      return Make_Presentation ("ab", Empty);
   end Free_AB;

begin
   Ada.Text_IO.Put_Line ("Todd–Coxeter coset enumeration — Ada 2023 tests");
   Ada.Text_IO.Put_Line ("Default_Max_Cosets =" & Default_Max_Cosets'Image);

   ------------------------------------------------------------------
   Section ("Make_Word / validation");
   ------------------------------------------------------------------
   declare
      X : constant Word := W ("abA");
   begin
      Check (X.Length = 3 and then X.Letters (1 .. 3) = "abA",
             "Make_Word (""abA"") accepts letters");
   end;

   declare
      Raised : Boolean := False;
   begin
      begin
         declare
            X : constant Word := W ("a1b");
            pragma Unreferenced (X);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Make_Word rejects non-letter '1'");
   end;

   declare
      Raised : Boolean := False;
      Long   : constant String (1 .. Max_Word_Length + 1) := [others => 'a'];
   begin
      begin
         declare
            X : constant Word := W (Long);
            pragma Unreferenced (X);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Make_Word rejects overlong string");
   end;

   declare
      Raised : Boolean := False;
   begin
      begin
         declare
            P : constant Presentation :=
              Make_Presentation ("aA", One ("aa"));
            pragma Unreferenced (P);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Make_Presentation rejects uppercase generator");
   end;

   declare
      Raised : Boolean := False;
   begin
      begin
         declare
            P : constant Presentation :=
              Make_Presentation ("aa", One ("aa"));
            pragma Unreferenced (P);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Make_Presentation rejects duplicate generators");
   end;

   declare
      Raised : Boolean := False;
      P     : constant Presentation := Cyclic (3);
   begin
      begin
         declare
            R : constant Result :=
              Enumerate (P, One ("b"), 32);
            pragma Unreferenced (R);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Enumerate rejects undeclared subgroup letter");
   end;

   declare
      Raised : Boolean := False;
      P     : constant Presentation := Cyclic (2);
   begin
      begin
         declare
            R : constant Result :=
              Enumerate (P, Empty_Subgroup, Default_Max_Cosets + 1);
            pragma Unreferenced (R);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Enumerate rejects Limit > Default_Max_Cosets");
   end;

   declare
      P : constant Presentation := S3;
   begin
      Check (Word_Is_Valid (P, W ("abAB")), "Word_Is_Valid accepts abAB in S3");
      Check (not Word_Is_Valid (P, W ("ac")), "Word_Is_Valid rejects 'c' in S3");
      Check (Column_Of (P, 'a') = 1, "Column_Of (S3, 'a') = 1");
      Check (Column_Of (P, 'b') = 2, "Column_Of (S3, 'b') = 2");
      Check (Column_Of (P, 'A') = 3, "Column_Of (S3, 'A') = Gen_Count+1");
      Check (Column_Of (P, 'B') = 4, "Column_Of (S3, 'B') = Gen_Count+2");
      Check (Column_Of (P, 'c') = 0, "Column_Of (S3, 'c') = 0");
   end;

   ------------------------------------------------------------------
   Section ("Cyclic groups C_n — trivial subgroup → |G|");
   ------------------------------------------------------------------
   Check (Expect_Index (Cyclic (1), Empty_Subgroup, 32, 1),
          "C1 = <a|a> index 1");
   Check (Expect_Index (Cyclic (2), Empty_Subgroup, 32, 2),
          "C2 index 2");
   Check (Expect_Index (Cyclic (3), Empty_Subgroup, 32, 3),
          "C3 index 3");
   Check (Expect_Index (Cyclic (4), Empty_Subgroup, 32, 4),
          "C4 index 4");
   Check (Expect_Index (Cyclic (5), Empty_Subgroup, 64, 5),
          "C5 index 5");
   Check (Expect_Index (Cyclic (6), Empty_Subgroup, 64, 6),
          "C6 index 6");
   Check (Expect_Index (Cyclic (7), Empty_Subgroup, 64, 7),
          "C7 index 7");
   Check (Expect_Index (Cyclic (8), Empty_Subgroup, 64, 8),
          "C8 index 8");
   Check (Expect_Index (Cyclic (12), Empty_Subgroup, 64, 12),
          "C12 index 12");

   ------------------------------------------------------------------
   Section ("Cyclic — H = G → index 1; proper subgroups");
   ------------------------------------------------------------------
   Check (Expect_Index (Cyclic (6), One ("a"), 32, 1),
          "C6 / <a> index 1");
   Check (Expect_Index (Cyclic (5), One ("a"), 32, 1),
          "C5 / <a> index 1");
   Check (Expect_Index (Cyclic (6), One ("aa"), 32, 2),
          "C6 / <a^2> index 2");
   Check (Expect_Index (Cyclic (6), One ("aaa"), 32, 3),
          "C6 / <a^3> index 3");
   Check (Expect_Index (Cyclic (8), One ("aa"), 32, 2),
          "C8 / <a^2> index 2");
   Check (Expect_Index (Cyclic (8), One ("aaaa"), 32, 4),
          "C8 / <a^4> index 4");
   Check (Expect_Index (Cyclic (9), One ("aaa"), 64, 3),
          "C9 / <a^3> index 3");
   Check (Expect_Index (Trivial_A, Empty_Subgroup, 16, 1),
          "Trivial <a|a> index 1");

   ------------------------------------------------------------------
   Section ("S3 — order 6");
   ------------------------------------------------------------------
   Check (Expect_Index (S3, Empty_Subgroup, 64, 6),
          "S3 / {1} index 6");
   Check (Expect_Index (S3, One ("a"), 64, 3),
          "S3 / <a> index 3");
   Check (Expect_Index (S3, One ("b"), 64, 2),
          "S3 / <b> index 2");
   Check (Expect_Index (S3, One ("bb"), 64, 2),
          "S3 / <b^2> (= <b>) index 2");
   Check (Expect_Index (S3, Two ("a", "b"), 64, 1),
          "S3 / <a,b> = G index 1");
   Check (Expect_Index (S3, One ("ab"), 64, 3),
          "S3 / <ab> index 3 (order-2)");

   declare
      P : constant Presentation := S3;
      R : constant Result := Enumerate (P, Empty_Subgroup, 64);
   begin
      Check (R.Success and then R.Columns = 4,
             "S3 table has 4 columns (a,b,A,B)");
      Check (R.Success and then Trace (R, P, 1, W ("aa")) = 1,
             "S3: 1 * a^2 = 1");
      Check (R.Success and then Trace (R, P, 1, W ("bbb")) = 1,
             "S3: 1 * b^3 = 1");
      --  Action of a on coset 1 is some coset; a^2 fixes every coset
      if R.Success then
         declare
            All_A2 : Boolean := True;
         begin
            for C in 1 .. R.Index loop
               if Trace (R, P, C, W ("aa")) /= Coset_Id (C) then
                  All_A2 := False;
               end if;
            end loop;
            Check (All_A2, "S3: a^2 fixes every coset");
         end;
      else
         Check (False, "S3: a^2 fixes every coset");
      end if;
   end;

   ------------------------------------------------------------------
   Section ("A4 — order 12");
   ------------------------------------------------------------------
   Check (Expect_Index (A4, Empty_Subgroup, 128, 12),
          "A4 / {1} index 12");
   Check (Expect_Index (A4, One ("a"), 128, 6),
          "A4 / <a> index 6");
   Check (Expect_Index (A4, One ("b"), 128, 4),
          "A4 / <b> index 4");
   Check (Expect_Index (A4, Two ("a", "b"), 128, 1),
          "A4 / G index 1");

   ------------------------------------------------------------------
   Section ("Klein four / dihedral / quaternion");
   ------------------------------------------------------------------
   Check (Expect_Index (V4, Empty_Subgroup, 32, 4),
          "V4 / {1} index 4");
   Check (Expect_Index (V4, One ("a"), 32, 2),
          "V4 / <a> index 2");
   Check (Expect_Index (V4, Two ("a", "b"), 32, 1),
          "V4 / G index 1");

   Check (Expect_Index (D4, Empty_Subgroup, 64, 8),
          "D4 / {1} index 8");
   Check (Expect_Index (D4, One ("a"), 64, 2),
          "D4 / <a> index 2");
   Check (Expect_Index (D4, One ("b"), 64, 4),
          "D4 / <b> index 4");
   Check (Expect_Index (D4, One ("aa"), 64, 4),
          "D4 / <a^2> index 4");

   Check (Expect_Index (D5, Empty_Subgroup, 64, 10),
          "D5 / {1} index 10");
   Check (Expect_Index (D5, One ("a"), 64, 2),
          "D5 / <a> index 2");
   Check (Expect_Index (D5, One ("b"), 64, 5),
          "D5 / <b> index 5");

   Check (Expect_Index (D6, Empty_Subgroup, 64, 12),
          "D6 / {1} index 12");

   Check (Expect_Index (Q8, Empty_Subgroup, 64, 8),
          "Q8 / {1} index 8");
   Check (Expect_Index (Q8, One ("a"), 64, 2),
          "Q8 / <a> index 2");
   Check (Expect_Index (Q8, One ("aa"), 64, 4),
          "Q8 / <a^2> (= centre) index 4");
   Check (Expect_Index (Q8, One ("b"), 64, 2),
          "Q8 / <b> index 2");
   Check (Expect_Index (Q8, Two ("a", "b"), 64, 1),
          "Q8 / G index 1");

   ------------------------------------------------------------------
   Section ("Limit exceeded / incomplete");
   ------------------------------------------------------------------
   Check (Expect_Fail (Free_AB, Empty_Subgroup, 8),
          "Free <a,b|> fails within Limit=8");
   Check (Expect_Fail (Free_AB, Empty_Subgroup, 32),
          "Free <a,b|> fails within Limit=32");
   Check (Expect_Fail (Cyclic (20), Empty_Subgroup, 5),
          "C20 fails with Limit=5 (< 20)");
   Check (Expect_Index (Cyclic (20), Empty_Subgroup, 32, 20),
          "C20 succeeds with Limit=32");

   --  C2 with tiny limit still works (index 2)
   Check (Expect_Index (C2, Empty_Subgroup, 2, 2),
          "C2 succeeds with Limit=2 exactly");
   Check (Expect_Fail (C2, Empty_Subgroup, 1),
          "C2 fails with Limit=1");

   ------------------------------------------------------------------
   Section ("Action table sanity");
   ------------------------------------------------------------------
   declare
      P : constant Presentation := V4;
      R : constant Result := Enumerate (P, Empty_Subgroup, 32);
      Ok : Boolean := R.Success;
   begin
      if Ok then
         for C in 1 .. R.Index loop
            for J in 1 .. R.Columns loop
               declare
                  Img : constant Coset_Id := Action (R, C, J);
               begin
                  if Img = 0 or else Img > Coset_Id (R.Index) then
                     Ok := False;
                  end if;
               end;
            end loop;
         end loop;
      end if;
      Check (Ok, "V4 action table is a total map to live cosets");
   end;

   declare
      P : constant Presentation := Cyclic (4);
      R : constant Result := Enumerate (P, Empty_Subgroup, 16);
   begin
      Check
        (R.Success
         and then Trace (R, P, 1, W ("aaaa")) = 1
         and then Trace (R, P, 1, W ("a")) /= 1,
         "C4: a^4 = 1 and a ≠ 1 on coset 1");
   end;

   ------------------------------------------------------------------
   --  Summary
   ------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image & " FAIL");

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
