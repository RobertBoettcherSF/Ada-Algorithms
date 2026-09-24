--  Standalone test suite for Zhu_Takaoka (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Zhu_Takaoka; use Zhu_Takaoka;

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

   procedure Expect_Agree (Pattern, Text, Label : String) is
      Z : constant Match_Index_Array := Search (Pattern, Text);
      N : constant Match_Index_Array := Naive_Search (Pattern, Text);
   begin
      Check (Same_Matches (Z, N), Label & " ZT=naive");
   end Expect_Agree;

   procedure Expect_Positions
     (Pattern, Text : String;
      Expected      : Match_Index_Array;
      Label         : String)
   is
      Got : constant Match_Index_Array := Search (Pattern, Text);
   begin
      Check (Same_Matches (Got, Expected), Label);
      Check (Same_Matches (Got, Naive_Search (Pattern, Text)),
             Label & " vs naive");
   end Expect_Positions;

   function Search_Raises (Pattern, Text : String) return Boolean is
   begin
      declare
         Unused : constant Match_Index_Array := Search (Pattern, Text);
         pragma Unreferenced (Unused);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Search_Raises;

   function Naive_Raises (Pattern, Text : String) return Boolean is
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
   end Naive_Raises;

begin
   Put_Line ("Zhu_Takaoka test suite");
   Put_Line ("======================");

   ---------------------------------------------------------------------
   Section ("1. Empty text / no match / pattern = text");
   ---------------------------------------------------------------------
   Expect_Positions ("abc", "", Match_Index_Array'(1 .. 0 => 1),
                     "empty text → no matches");
   Expect_Positions ("abc", "xyz", Match_Index_Array'(1 .. 0 => 1),
                     "no match xyz");
   Expect_Positions ("hello", "hello", Match_Index_Array'(1 => 1),
                     "pattern = text");
   Expect_Agree ("hello", "hello", "pattern=text");
   Expect_Agree ("abc", "", "empty text");
   Expect_Agree ("zzz", "aaabbcc", "no match");

   ---------------------------------------------------------------------
   Section ("2. Single character");
   ---------------------------------------------------------------------
   Expect_Positions ("a", "a", Match_Index_Array'(1 => 1),
                     "single char equal");
   Expect_Positions ("a", "banana",
                     Match_Index_Array'(1 => 2, 2 => 4, 3 => 6),
                     "a in banana");
   Expect_Positions ("x", "banana", Match_Index_Array'(1 .. 0 => 1),
                     "x not in banana");
   Expect_Agree ("a", "aaaaaaaa", "aaaa single");
   Expect_Agree ("b", "abababab", "b in abab");
   Expect_Agree ("z", "yyyyyyyy", "z absent");

   ---------------------------------------------------------------------
   Section ("3. Overlapping matches");
   ---------------------------------------------------------------------
   Expect_Positions ("aa", "aaaa",
                     Match_Index_Array'(1 => 1, 2 => 2, 3 => 3),
                     "aa in aaaa overlapping");
   Expect_Positions ("aba", "abababa",
                     Match_Index_Array'(1 => 1, 2 => 3, 3 => 5),
                     "aba overlapping");
   Expect_Agree ("aa", "aaaaaaa", "aa overlap");
   Expect_Agree ("aaa", "aaaaaaaaaa", "aaa overlap");
   Expect_Agree ("abab", "ababababab", "abab overlap");

   ---------------------------------------------------------------------
   Section ("4. Classic examples vs naive");
   ---------------------------------------------------------------------
   Expect_Agree ("GCAGAGAG", "GCATCGCAGAGAGTATACAGTACG", "Lecroq-style");
   Expect_Agree ("announce", "annual_announce_announcement", "announce");
   Expect_Agree ("needle", "haystack needle hay", "needle");
   Expect_Agree ("AT-CG", "AT-CGAT-CG", "AT-CG");
   Expect_Agree ("the", "the theater then them", "the");
   Expect_Agree ("ing", "string matching searching", "ing");

   ---------------------------------------------------------------------
   Section ("5. Pattern at start / middle / end");
   ---------------------------------------------------------------------
   Expect_Positions ("foo", "foobar", Match_Index_Array'(1 => 1),
                     "at start");
   Expect_Positions ("bar", "foobar", Match_Index_Array'(1 => 4),
                     "at end");
   Expect_Positions ("oba", "foobar", Match_Index_Array'(1 => 3),
                     "in middle");
   Expect_Agree ("foo", "foofoofoo", "repeated foo");
   Expect_Agree ("bar", "xxbarxxbarxx", "bar twice");

   ---------------------------------------------------------------------
   Section ("6. Two-character patterns (digram table)");
   ---------------------------------------------------------------------
   Expect_Agree ("ab", "abababab", "ab digram");
   Expect_Agree ("ba", "abababab", "ba digram");
   Expect_Agree ("aa", "abaabaaaba", "aa digram");
   Expect_Agree ("zz", "zzzzz", "zz all");
   Expect_Positions ("ab", "ab", Match_Index_Array'(1 => 1),
                     "ab = text");

   ---------------------------------------------------------------------
   Section ("7. Invalid empty pattern");
   ---------------------------------------------------------------------
   Check (Search_Raises ("", "text"), "empty pattern Search raises");
   Check (Search_Raises ("", ""), "empty pattern+text Search raises");
   Check (Naive_Raises ("", "abc"), "empty pattern Naive raises");
   Check (Naive_Raises ("", ""), "empty both Naive raises");

   ---------------------------------------------------------------------
   Section ("8. Longer / varied alphabets");
   ---------------------------------------------------------------------
   Expect_Agree ("algorithm",
                 "this is an algorithm for string matching algorithms",
                 "algorithm word");
   Expect_Agree ("123", "x123y123z123", "digits");
   Expect_Agree ("A!", "xxA!yyA!", "punct");
   Expect_Agree ("  ", "a  b  c  ", "spaces");
   Expect_Agree ("MiXeD", "MiXeD MiXeD case", "mixed case");

   ---------------------------------------------------------------------
   Section ("9. Exhaustive short pairs vs naive");
   ---------------------------------------------------------------------
   declare
      type Str_Access is access constant String;
      Patterns : constant array (Positive range <>) of Str_Access :=
        [new String'("a"), new String'("b"), new String'("ab"),
         new String'("ba"), new String'("aa"), new String'("abc"),
         new String'("cba"), new String'("aaa"), new String'("aba"),
         new String'("bab")];
      Texts : constant array (Positive range <>) of Str_Access :=
        [new String'(""), new String'("a"), new String'("b"),
         new String'("ab"), new String'("ba"), new String'("aa"),
         new String'("bb"), new String'("abc"), new String'("cba"),
         new String'("abab"), new String'("baba"), new String'("aaaa"),
         new String'("abababab"), new String'("aaabaaabaaab")];
   begin
      for P of Patterns loop
         for T of Texts loop
            Expect_Agree
              (P.all, T.all, "'" & P.all & "' in '" & T.all & "'");
         end loop;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("10. Pattern longer than text");
   ---------------------------------------------------------------------
   Expect_Positions ("abcdef", "abc", Match_Index_Array'(1 .. 0 => 1),
                     "pattern longer");
   Expect_Agree ("longer", "short", "longer");

   ---------------------------------------------------------------------
   Section ("11. Multiple occurrences");
   ---------------------------------------------------------------------
   Expect_Agree ("cat", "concatenate catalog cat", "cat multi");
   Expect_Agree ("an", "banana bandana", "an multi");
   Expect_Agree ("iss", "Mississippi", "iss Mississippi");
   Expect_Agree ("ssi", "Mississippi", "ssi Mississippi");

   ---------------------------------------------------------------------
   Section ("12. Binary-ish / repetitive");
   ---------------------------------------------------------------------
   Expect_Agree ("01", "01010101", "01 binary");
   Expect_Agree ("10", "01010101", "10 binary");
   Expect_Agree ("000", "0001000", "000 bits");
   Expect_Agree ("1111", "0111101111", "1111 bits");

   ---------------------------------------------------------------------
   Section ("13. API smoke / digram positions");
   ---------------------------------------------------------------------
   declare
      R : constant Match_Index_Array := Search ("xy", "abxyabxy");
      S : constant Match_Index_Array := Search ("CG", "ATCGATCG");
   begin
      Check (R'Length = 2, "xy two hits length");
      Check (R (1) = 3, "xy first at 3");
      Check (R (2) = 7, "xy second at 7");
      Check (S'Length = 2, "CG two hits");
      Check (S (1) = 3 and then S (2) = 7, "CG at 3 and 7");
      Expect_Agree ("ZT", "Zhu-Takaoka ZT demo ZT", "ZT token");
   end;

   New_Line;
   Put_Line
     ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image
      & " FAIL");

   if Fail_Count /= 0 then
      raise Program_Error with "Zhu_Takaoka tests failed";
   end if;
end Tests;
