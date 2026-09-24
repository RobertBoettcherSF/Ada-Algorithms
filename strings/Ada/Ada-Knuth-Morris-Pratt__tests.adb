--  Standalone test suite for Knuth_Morris_Pratt (main program).

pragma Ada_2022;

with Ada.Text_IO;         use Ada.Text_IO;
with Knuth_Morris_Pratt;  use Knuth_Morris_Pratt;

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

   procedure Expect_Agree (Pattern, Text, Label : String) is
      R : constant Match_Index_Array := Search (Pattern, Text);
      N : constant Match_Index_Array := Naive_Search (Pattern, Text);
   begin
      Check (Same_Matches (R, N), Label & " KMP=naive");
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

   procedure Expect_LPS
     (Pattern  : String;
      Expected : LPS_Array;
      Label    : String)
   is
      Got  : constant LPS_Array := Build_LPS (Pattern);
      Got2 : constant LPS_Array := Prefix_Table (Pattern);
   begin
      Check (Same_LPS (Got, Expected), Label & " Build_LPS");
      Check (Same_LPS (Got2, Expected), Label & " Prefix_Table");
      Check (Same_LPS (Got, Got2), Label & " Build_LPS=Prefix_Table");
   end Expect_LPS;

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

begin
   Put_Line ("Knuth_Morris_Pratt test suite");
   Put_Line ("=============================");

   ---------------------------------------------------------------------
   Section ("1. LPS classic patterns");
   ---------------------------------------------------------------------
   --  AABAACAABABA → [0,1,0,1,2,0,1,2,3,4,0,1]
   Expect_LPS
     ("AABAACAABABA",
      LPS_Array'(0, 1, 0, 1, 2, 0, 1, 2, 3, 4, 0, 1),
      "AABAACAABABA");
   --  ABCDABD → [0,0,0,0,1,2,0]
   Expect_LPS
     ("ABCDABD",
      LPS_Array'(0, 0, 0, 0, 1, 2, 0),
      "ABCDABD");
   --  AAAAA → [0,1,2,3,4]
   Expect_LPS
     ("AAAAA",
      LPS_Array'(0, 1, 2, 3, 4),
      "AAAAA");
   --  ABCDE → [0,0,0,0,0]
   Expect_LPS
     ("ABCDE",
      LPS_Array'(0, 0, 0, 0, 0),
      "ABCDE");
   --  AAACAAAAAC → [0,1,2,0,1,2,3,3,3,4]  wait let me compute carefully
   --  A A A C A A A A A C
   --  0 1 2 0 1 2 3 4 5 0 ? 
   --  Actually: AAACAAAAAC
   --  i=2 A=A len=1 lps=1
   --  i=3 A=A len=2 lps=2
   --  i=4 C!=A len=lps[2]=1; C!=A len=lps[1]=0; C!=A lps=0
   --  i=5 A=A len=1 lps=1
   --  i=6 A=A len=2 lps=2
   --  i=7 A=A len=3 lps=3
   --  i=8 A!=C len=lps[3]=0; A=A? wait after len=0, A==A so we go to first branch...
   --  Careful: after elif Len /= 0, we don't increment I, we retry
   --  i=8, Len was 3, A != C, Len := LPS(3)=0
   --  i=8, Len=0, A !=? we go to else: LPS(8)=0, I=9
   --  WAIT Pattern[8] is A (1-based: AAACAAAA AC positions 1..10)
   --  Pattern: 1:A 2:A 3:A 4:C 5:A 6:A 7:A 8:A 9:A 10:C
   --  i=8 Len=3: Pattern(8)=A, Pattern(1+3)=Pattern(4)=C, A!=C
   --  Len=LPS(3)=2; Pattern(8)=A, Pattern(1+2)=Pattern(3)=A, match!
   --  Len=3, LPS(8)=3, I=9
   --  i=9 Len=3: Pattern(9)=A, Pattern(4)=C, A!=C
   --  Len=LPS(3)=2; A vs Pattern(3)=A, match Len=3 LPS(9)=3 I=10
   --  i=10 Len=3: Pattern(10)=C, Pattern(4)=C, match Len=4 LPS(10)=4
   --  So LPS = [0,1,2,0,1,2,3,3,3,4]
   Expect_LPS
     ("AAACAAAAAC",
      LPS_Array'(0, 1, 2, 0, 1, 2, 3, 3, 3, 4),
      "AAACAAAAAC");
   Expect_LPS ("a", LPS_Array'(1 => 0), "single a");
   Expect_LPS ("ab", LPS_Array'(0, 0), "ab");
   Expect_LPS ("aa", LPS_Array'(0, 1), "aa");

   ---------------------------------------------------------------------
   Section ("2. Empty text / no match / pattern = text");
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
   Section ("3. Single character");
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
   Section ("4. Overlapping matches");
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
   Expect_Agree ("AABA", "AABAACAABABA", "AABA in classic");

   ---------------------------------------------------------------------
   Section ("5. Classic Wikipedia / textbook examples");
   ---------------------------------------------------------------------
   Expect_Agree ("ABCDABD", "ABC ABCDAB ABCDABCDABDE", "wiki ABCDABD");
   Expect_Agree ("bra", "abracadabra", "wiki bra");
   Expect_Agree ("abr", "abracadabra", "wiki abr");
   Expect_Agree ("announce", "annual_announce_announcement", "announce");
   Expect_Agree ("needle", "haystack needle hay", "needle");
   Expect_Agree ("AT-CG", "AT-CGAT-CG", "AT-CG");
   Expect_Agree ("the", "the theater then them", "the");
   Expect_Agree ("ing", "string matching searching", "ing");
   Expect_Positions
     ("ABCDABD", "ABC ABCDAB ABCDABCDABDE",
      Match_Index_Array'(1 => 16),
      "wiki single hit at 16");

   ---------------------------------------------------------------------
   Section ("6. Pattern at start / middle / end");
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
   Section ("7. Invalid empty pattern");
   ---------------------------------------------------------------------
   Check (Search_Raises ("", "text"), "empty pattern Search raises");
   Check (Search_Raises ("", ""), "empty pattern+text Search raises");
   Check (Naive_Raises ("", "abc"), "empty pattern Naive raises");
   Check (Naive_Raises ("", ""), "empty both Naive raises");
   Check (LPS_Raises (""), "empty pattern Build_LPS raises");

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
   Section ("13. API smoke / Prefix_Table rename");
   ---------------------------------------------------------------------
   declare
      R   : constant Match_Index_Array := Search ("xy", "abxyabxy");
      S   : constant Match_Index_Array := Search ("CG", "ATCGATCG");
      LPS : constant LPS_Array := Prefix_Table ("AABAACAABABA");
   begin
      Check (R'Length = 2, "xy two hits length");
      Check (R (1) = 3, "xy first at 3");
      Check (R (2) = 7, "xy second at 7");
      Check (S'Length = 2, "CG two hits");
      Check (S (1) = 3 and then S (2) = 7, "CG at 3 and 7");
      Check (LPS'Length = 12, "LPS length 12");
      Check (LPS (1) = 0 and then LPS (12) = 1, "LPS ends 0…1");
      Expect_Agree ("KMP", "demo KMP algorithm KMP", "KMP token");
   end;

   New_Line;
   Put_Line
     ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image
      & " FAIL");

   if Fail_Count /= 0 then
      raise Program_Error with "Knuth_Morris_Pratt tests failed";
   end if;
end Tests;
