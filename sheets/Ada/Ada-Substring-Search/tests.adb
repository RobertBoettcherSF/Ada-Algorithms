--  Standalone test suite for Substring_Search (survey package main).

pragma Ada_2022;

with Ada.Text_IO;      use Ada.Text_IO;
with Substring_Search; use Substring_Search;

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

   function Same_Matches
     (A, B : Match_Index_Array) return Boolean
   is
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
   end Same_Matches;

   function Same_LPS (A, B : LPS_Array) return Boolean is
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
   end Same_LPS;

   --  All four searchers (+ dispatcher for each method) must match Naive.
   procedure Expect_All_Agree (Pattern, Text, Label : String) is
      N   : constant Match_Index_Array := Naive_Search (Pattern, Text);
      K   : constant Match_Index_Array := KMP_Search (Pattern, Text);
      R   : constant Match_Index_Array := Rabin_Karp_Search (Pattern, Text);
      H   : constant Match_Index_Array :=
              Boyer_Moore_Horspool_Search (Pattern, Text);
      DN  : constant Match_Index_Array := Search (Pattern, Text, Naive);
      DK  : constant Match_Index_Array := Search (Pattern, Text, KMP);
      DR  : constant Match_Index_Array := Search (Pattern, Text, Rabin_Karp);
      DH  : constant Match_Index_Array :=
              Search (Pattern, Text, Boyer_Moore_Horspool);
   begin
      Check (Same_Matches (K, N),  Label & " KMP=naive");
      Check (Same_Matches (R, N),  Label & " RK=naive");
      Check (Same_Matches (H, N),  Label & " BMH=naive");
      Check (Same_Matches (DN, N), Label & " dispatch Naive=naive");
      Check (Same_Matches (DK, N), Label & " dispatch KMP=naive");
      Check (Same_Matches (DR, N), Label & " dispatch RK=naive");
      Check (Same_Matches (DH, N), Label & " dispatch BMH=naive");
   end Expect_All_Agree;

   procedure Expect_Positions
     (Pattern, Text : String;
      Expected      : Match_Index_Array;
      Label         : String)
   is
      Got : constant Match_Index_Array := Naive_Search (Pattern, Text);
   begin
      Check (Same_Matches (Got, Expected), Label & " positions");
      Expect_All_Agree (Pattern, Text, Label);
   end Expect_Positions;

   function Raises_Empty (Pattern, Text : String) return Boolean is
   begin
      declare
         Unused : constant Match_Index_Array := Naive_Search (Pattern, Text);
         pragma Unreferenced (Unused);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Raises_Empty;

   function KMP_Raises (Pattern, Text : String) return Boolean is
   begin
      declare
         Unused : constant Match_Index_Array := KMP_Search (Pattern, Text);
         pragma Unreferenced (Unused);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end KMP_Raises;

   function RK_Raises (Pattern, Text : String) return Boolean is
   begin
      declare
         Unused : constant Match_Index_Array :=
           Rabin_Karp_Search (Pattern, Text);
         pragma Unreferenced (Unused);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end RK_Raises;

   function BMH_Raises (Pattern, Text : String) return Boolean is
   begin
      declare
         Unused : constant Match_Index_Array :=
           Boyer_Moore_Horspool_Search (Pattern, Text);
         pragma Unreferenced (Unused);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end BMH_Raises;

   function LPS_Raises (Pattern : String) return Boolean is
   begin
      declare
         Unused : constant LPS_Array := Build_LPS (Pattern);
         pragma Unreferenced (Unused);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end LPS_Raises;

   function BC_Raises (Pattern : String) return Boolean is
   begin
      declare
         Unused : constant Bad_Character_Table :=
           Build_Bad_Character (Pattern);
         pragma Unreferenced (Unused);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end BC_Raises;

   function RK_Modulus_Raises return Boolean is
   begin
      declare
         Unused : constant Match_Index_Array :=
           Rabin_Karp_Search ("a", "a", Modulus => 1);
         pragma Unreferenced (Unused);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end RK_Modulus_Raises;

begin
   Put_Line ("Substring_Search survey test suite");
   Put_Line ("==================================");

   ---------------------------------------------------------------------
   Section ("1. Classic positions");
   ---------------------------------------------------------------------
   Expect_Positions
     ("to",
      "Some books are to be tasted, others to be swallowed, and some few to be chewed and digested.",
      Match_Index_Array'(16, 37, 67),
      "Bacon to");
   Expect_Positions
     ("ABAB",
      "ABABABAB",
      Match_Index_Array'(1, 3, 5),
      "overlapping ABAB");
   Expect_Positions
     ("AAA",
      "AAAAA",
      Match_Index_Array'(1, 2, 3),
      "overlapping AAA");
   Expect_Positions
     ("needle",
      "find the needle in the haystack",
      Match_Index_Array'(1 => 10),
      "single needle");
   Expect_Positions
     ("xyz",
      "abcdefgh",
      Match_Index_Array'(1 .. 0 => 1),
      "no match");

   ---------------------------------------------------------------------
   Section ("2. Edge lengths");
   ---------------------------------------------------------------------
   Expect_All_Agree ("a", "", "empty text");
   Expect_All_Agree ("a", "a", "equal length match");
   Expect_All_Agree ("ab", "a", "pattern longer");
   Expect_All_Agree ("x", "xxxxxxxxxx", "all hits char");
   Expect_All_Agree ("aa", "aaaaaaaa", "dense overlaps");
   Expect_All_Agree ("Z", "abc", "absent single");
   Expect_All_Agree ("the", "the the the", "repeated word");

   ---------------------------------------------------------------------
   Section ("3. LPS table");
   ---------------------------------------------------------------------
   declare
      L1 : constant LPS_Array := Build_LPS ("AABAACAABABA");
      L2 : constant LPS_Array := Build_LPS ("ABCDABD");
      L3 : constant LPS_Array := Build_LPS ("AAAAA");
      L4 : constant LPS_Array := Build_LPS ("ABCDE");
      L5 : constant LPS_Array := Build_LPS ("A");
   begin
      Check (Same_LPS (L1, LPS_Array'(0, 1, 0, 1, 2, 0, 1, 2, 3, 4, 0, 1)),
             "LPS AABAACAABABA");
      Check (Same_LPS (L2, LPS_Array'(0, 0, 0, 0, 1, 2, 0)),
             "LPS ABCDABD");
      Check (Same_LPS (L3, LPS_Array'(0, 1, 2, 3, 4)),
             "LPS AAAAA");
      Check (Same_LPS (L4, LPS_Array'(0, 0, 0, 0, 0)),
             "LPS ABCDE");
      Check (Same_LPS (L5, LPS_Array'(1 => 0)),
             "LPS single A");
   end;

   ---------------------------------------------------------------------
   Section ("4. Empty pattern / invalid args");
   ---------------------------------------------------------------------
   Check (Raises_Empty ("", "haystack"), "Naive empty pattern");
   Check (KMP_Raises ("", "haystack"), "KMP empty pattern");
   Check (RK_Raises ("", "haystack"), "RK empty pattern");
   Check (BMH_Raises ("", "haystack"), "BMH empty pattern");
   Check (LPS_Raises (""), "Build_LPS empty");
   Check (BC_Raises (""), "Build_Bad_Character empty");
   Check (RK_Modulus_Raises, "RK modulus < 2");

   ---------------------------------------------------------------------
   Section ("5. Diverse alphabets / cases");
   ---------------------------------------------------------------------
   Expect_All_Agree ("ACGT", "ACGTACGTACGT", "DNA repeat");
   Expect_All_Agree ("01", "0010100110", "binary");
   Expect_All_Agree ("Hi", "hiHiHIHi", "case sensitive");
   Expect_All_Agree ("  ", "a  b  c", "spaces");
   Expect_All_Agree ("na", "banana", "banana na");
   Expect_All_Agree ("ana", "banana", "banana ana");
   Expect_All_Agree ("anana", "banana", "banana anana");
   Expect_All_Agree ("GCAGAGAG", "GCATCGCAGAGAGTATACAGTACG", "CLRS-ish");
   Expect_All_Agree ("ABCDABD", "ABC ABCDAB ABCDABCDABDE", "KMP wiki");
   Expect_All_Agree ("abab", "abacababab", "prefix border");

   ---------------------------------------------------------------------
   Section ("6. Horspool skip sanity");
   ---------------------------------------------------------------------
   declare
      Bc : constant Bad_Character_Table := Build_Bad_Character ("GCAGAGAG");
      --  m = 8; last char G excluded from table fill for rightmost in 0..m-2
   begin
      Check (Bc (Character'Pos ('G')) = 2
               or else Bc (Character'Pos ('G')) = 4
               or else Bc (Character'Pos ('G')) /= 0,
             "BC G nonzero for GCAGAGAG");
      Check (Bc (Character'Pos ('X')) = 8, "BC absent X -> m");
      Check (Bc (Character'Pos ('A')) < 8, "BC A < m");
   end;

   ---------------------------------------------------------------------
   Section ("7. Rabin–Karp alternate base/modulus");
   ---------------------------------------------------------------------
   declare
      P : constant String := "pattern";
      T : constant String := "this is a pattern in text with pattern";
      N : constant Match_Index_Array := Naive_Search (P, T);
      R1 : constant Match_Index_Array :=
        Rabin_Karp_Search (P, T, Base => 31, Modulus => 1_000_003);
      R2 : constant Match_Index_Array :=
        Rabin_Karp_Search (P, T, Base => 257, Modulus => 998_244_353);
   begin
      Check (Same_Matches (R1, N), "RK base 31 = naive");
      Check (Same_Matches (R2, N), "RK base 257 = naive");
   end;

   ---------------------------------------------------------------------
   Section ("8. Long-ish / repetitive");
   ---------------------------------------------------------------------
   declare
      Text : constant String :=
        "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaab";
   begin
      Expect_All_Agree ("aaaab", Text, "worstish aaaab");
      Expect_All_Agree ("aaaaa", Text, "worstish aaaaa");
      Expect_All_Agree ("b", Text, "trailing b");
   end;

   Expect_All_Agree
     ("algorithm",
      "A string-searching algorithm, sometimes called string-matching algorithm.",
      "wiki sentence");

   ---------------------------------------------------------------------
   Section ("9. Dispatcher default");
   ---------------------------------------------------------------------
   declare
      N : constant Match_Index_Array := Naive_Search ("ab", "xxabyyab");
      D : constant Match_Index_Array := Search ("ab", "xxabyyab");
   begin
      Check (Same_Matches (D, N), "default Method=Naive");
      Check (N'Length = 2 and then N (1) = 3 and then N (2) = 7,
             "xxabyyab positions");
   end;

   ---------------------------------------------------------------------
   Section ("10. Slice / non-1'First strings");
   ---------------------------------------------------------------------
   declare
      Buf : constant String := "___FINDME___FINDME";
      Pat : String renames Buf (4 .. 9);
      Txt : String renames Buf (1 .. Buf'Last);
   begin
      Expect_All_Agree (Pat, Txt, "non-1 First pattern/text");
   end;

   New_Line;
   Put_Line
     ("Results: " & Natural'Image (Pass_Count) & " PASS,"
      & Natural'Image (Fail_Count) & " FAIL");

   if Fail_Count /= 0 then
      raise Program_Error with "test failures present";
   end if;
end Tests;
