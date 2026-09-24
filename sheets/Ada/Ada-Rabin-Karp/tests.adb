--  Standalone test suite for Rabin_Karp (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Rabin_Karp;  use Rabin_Karp;

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
      R : constant Match_Index_Array := Search (Pattern, Text);
      N : constant Match_Index_Array := Naive_Search (Pattern, Text);
   begin
      Check (Same_Matches (R, N), Label & " RK=naive");
   end Expect_Agree;

   procedure Expect_Agree_Params
     (Pattern, Text : String;
      Base, Modulus : Positive;
      Label         : String)
   is
      R : constant Match_Index_Array :=
        Search (Pattern, Text, Base => Base, Modulus => Modulus);
      N : constant Match_Index_Array := Naive_Search (Pattern, Text);
   begin
      Check (Same_Matches (R, N), Label & " RK=naive");
   end Expect_Agree_Params;

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

   function Search_Mod_Raises
     (Pattern, Text : String;
      Modulus       : Positive) return Boolean
   is
   begin
      declare
         Unused : constant Match_Index_Array :=
           Search (Pattern, Text, Modulus => Modulus);
         pragma Unreferenced (Unused);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Search_Mod_Raises;

begin
   Put_Line ("Rabin_Karp test suite");
   Put_Line ("=====================");

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
   Expect_Agree ("bra", "abracadabra", "wiki bra");
   Expect_Agree ("abr", "abracadabra", "wiki abr");
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
   Section ("6. Invalid empty pattern / bad modulus");
   ---------------------------------------------------------------------
   Check (Search_Raises ("", "text"), "empty pattern Search raises");
   Check (Search_Raises ("", ""), "empty pattern+text Search raises");
   Check (Naive_Raises ("", "abc"), "empty pattern Naive raises");
   Check (Naive_Raises ("", ""), "empty both Naive raises");
   Check (Search_Mod_Raises ("ab", "abab", 1), "modulus 1 raises");

   ---------------------------------------------------------------------
   Section ("7. Tiny modulus — hash collisions still verified");
   ---------------------------------------------------------------------
   --  Q=13 / Q=101 force many collisions; exact compare must keep
   --  results identical to the naive oracle (no false positives).
   Expect_Agree_Params ("ab", "abababab", 256, 13, "ab Q=13");
   Expect_Agree_Params ("aa", "aaaaaaaa", 256, 13, "aa Q=13");
   Expect_Agree_Params ("bra", "abracadabra", 256, 101, "bra Q=101");
   Expect_Agree_Params ("hi", "xhighixhi", 256, 101, "hi Q=101");
   Expect_Agree_Params ("abc", "xabcyabczabc", 31, 97, "abc B=31 Q=97");
   Expect_Agree_Params ("a", "banana", 256, 7, "a Q=7");
   Expect_Agree_Params ("issi", "Mississippi", 256, 11, "issi Q=11");
   Expect_Agree_Params ("rabin", "karp-rabin-karp", 256, 17, "rabin Q=17");

   declare
      --  Colliding modulus: still only true matches
      Got : constant Match_Index_Array :=
        Search ("aa", "abacabad", Base => 256, Modulus => 5);
      Nai : constant Match_Index_Array := Naive_Search ("aa", "abacabad");
   begin
      Check (Same_Matches (Got, Nai), "aa Q=5 no false positives");
      Check (Got'Length = 0, "aa absent in abacabad");
   end;

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
   Section ("13. Default params / API smoke");
   ---------------------------------------------------------------------
   declare
      R : constant Match_Index_Array := Search ("xy", "abxyabxy");
      S : constant Match_Index_Array := Search ("CG", "ATCGATCG");
      D : constant Match_Index_Array :=
        Search ("rk", "rabin-karp rk demo rk",
                Base => Default_Base, Modulus => Default_Modulus);
   begin
      Check (R'Length = 2, "xy two hits length");
      Check (R (1) = 3, "xy first at 3");
      Check (R (2) = 7, "xy second at 7");
      Check (S'Length = 2, "CG two hits");
      Check (S (1) = 3 and then S (2) = 7, "CG at 3 and 7");
      Check (D'Length = 2, "rk two hits");
      declare
         E : constant Match_Index_Array :=
           Search ("rk", "rabin-karp rk demo rk");
         F : constant Match_Index_Array :=
           Search ("xy", "abxyabxy",
                   Base => Default_Base, Modulus => Default_Modulus);
      begin
         Check (Same_Matches (D, E), "explicit defaults = omitted");
         Check (Same_Matches (F, R), "defaults match xy smoke");
      end;
      Expect_Agree ("RK", "Rabin-Karp RK demo RK", "RK token");
   end;

   ---------------------------------------------------------------------
   Section ("14. Alternate bases agree with naive");
   ---------------------------------------------------------------------
   Expect_Agree_Params ("test", "contest testing latest", 31, Default_Modulus,
                        "B=31");
   Expect_Agree_Params ("test", "contest testing latest", 131, 1_000_003,
                        "B=131 Q=1e6+3");
   Expect_Agree_Params ("xx", "yxxzxxw", 2, 1_000_000_007, "B=2");

   New_Line;
   Put_Line
     ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image
      & " FAIL");

   if Fail_Count /= 0 then
      raise Program_Error with "Rabin_Karp tests failed";
   end if;
end Tests;
