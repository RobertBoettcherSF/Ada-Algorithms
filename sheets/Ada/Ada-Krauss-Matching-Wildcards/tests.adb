--  Standalone test suite for Krauss_Matching_Wildcards (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Krauss_Matching_Wildcards; use Krauss_Matching_Wildcards;

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
         Put_Line ("  PASS — " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  FAIL — " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      New_Line;
      Put_Line ("=== " & Title & " ===");
   end Section;

   --  Simple correct recursive oracle (short strings only). Used to
   --  cross-check Krauss Match on carefully chosen cases.
   function Oracle (Pattern, Text : String) return Boolean is
   begin
      if Pattern'Length = 0 then
         return Text'Length = 0;
      end if;

      if Pattern (Pattern'First) = '*' then
         --  '*' matches empty, or one more character then same '*'.
         if Oracle (Pattern (Pattern'First + 1 .. Pattern'Last), Text) then
            return True;
         elsif Text'Length > 0 then
            return Oracle (Pattern, Text (Text'First + 1 .. Text'Last));
         else
            return False;
         end if;
      end if;

      if Text'Length = 0 then
         return False;
      end if;

      if Pattern (Pattern'First) = '?'
        or else Pattern (Pattern'First) = Text (Text'First)
      then
         return Oracle
           (Pattern (Pattern'First + 1 .. Pattern'Last),
            Text (Text'First + 1 .. Text'Last));
      end if;

      return False;
   end Oracle;

   procedure Expect
     (Pattern, Text : String;
      Wanted        : Boolean;
      Label         : String)
   is
      Got : constant Boolean := Match (Pattern, Text);
   begin
      Check (Got = Wanted,
             Label & "  Pattern=""" & Pattern & """ Text=""" & Text
             & """ → " & (if Wanted then "True" else "False"));
   end Expect;

   procedure Expect_Oracle
     (Pattern, Text : String;
      Label         : String)
   is
      Wanted : constant Boolean := Oracle (Pattern, Text);
      Got    : constant Boolean := Match (Pattern, Text);
   begin
      Check (Got = Wanted,
             Label & "  (oracle) Pattern=""" & Pattern
             & """ Text=""" & Text & """");
   end Expect_Oracle;

begin
   Put_Line ("Krauss_Matching_Wildcards test suite");
   Put_Line ("====================================");

   ---------------------------------------------------------------------
   Section ("1. Empty pattern / empty text");
   ---------------------------------------------------------------------
   Expect ("", "", True,  "1.1 empty matches empty");
   Expect ("", "a", False, "1.2 empty does not match non-empty");
   Expect ("", "abc", False, "1.3 empty does not match longer");
   Expect ("*", "", True,  "1.4 star matches empty text");
   Expect ("**", "", True, "1.5 consecutive stars match empty");
   Expect ("?", "", False, "1.6 ? does not match empty");
   Expect ("a", "", False, "1.7 literal does not match empty");
   Expect ("*a*", "", False, "1.8 *a* does not match empty");

   ---------------------------------------------------------------------
   Section ("2. Literals (case-sensitive)");
   ---------------------------------------------------------------------
   Expect ("abc", "abc", True,  "2.1 exact literal");
   Expect ("abc", "abd", False, "2.2 mismatch last char");
   Expect ("abc", "ab", False,  "2.3 text too short");
   Expect ("ab", "abc", False,  "2.4 text too long");
   Expect ("Abc", "abc", False, "2.5 case-sensitive mismatch");
   Expect ("ABC", "ABC", True,  "2.6 uppercase exact");
   Expect ("a b", "a b", True,  "2.7 space is literal");
   Expect (".", ".", True,      "2.8 punctuation literal");

   ---------------------------------------------------------------------
   Section ("3. Single '?' wildcard");
   ---------------------------------------------------------------------
   Expect ("?", "a", True,   "3.1 ? matches one");
   Expect ("?", "", False,   "3.2 ? rejects empty");
   Expect ("?", "ab", False, "3.3 ? rejects two");
   Expect ("??", "ab", True, "3.4 ?? matches two");
   Expect ("a?c", "abc", True,  "3.5 a?c middle");
   Expect ("a?c", "aXc", True,  "3.6 a?c any middle");
   Expect ("a?c", "ac", False,  "3.7 a?c needs middle");
   Expect ("???", "xyz", True,  "3.8 three ?");
   Expect ("a?", "a", False,    "3.9 trailing ? needs char");

   ---------------------------------------------------------------------
   Section ("4. Single '*' wildcard");
   ---------------------------------------------------------------------
   Expect ("*", "anything", True, "4.1 * matches any");
   Expect ("*", "", True,         "4.2 * matches empty");
   Expect ("a*", "a", True,       "4.3 a* prefix only");
   Expect ("a*", "abc", True,     "4.4 a* prefix longer");
   Expect ("a*", "b", False,      "4.5 a* wrong prefix");
   Expect ("*c", "c", True,       "4.6 *c suffix only");
   Expect ("*c", "abc", True,     "4.7 *c suffix longer");
   Expect ("*c", "abd", False,    "4.8 *c wrong suffix");
   Expect ("*foo*", "foo", True,  "4.9 *foo* exact");
   Expect ("*foo*", "xfooy", True,"4.10 *foo* surround");
   Expect ("*foo*", "fo", False,  "4.11 *foo* missing");
   Expect ("mini*", "mini", True, "4.12 mini* exact (wiki)");
   Expect ("mini*", "minicomputer", True, "4.13 mini* longer (wiki)");

   ---------------------------------------------------------------------
   Section ("5. Mixed '*' and '?'");
   ---------------------------------------------------------------------
   Expect ("???*", "abc", True,   "5.1 ???* three-or-more (wiki)");
   Expect ("???*", "ab", False,   "5.2 ???* rejects two");
   Expect ("???*", "abcd", True,  "5.3 ???* four");
   Expect ("a*b?c", "abXc", True, "5.4 a*b?c empty star");
   Expect ("a*b?c", "axxbYc", True, "5.5 a*b?c with fill");
   Expect ("a*b?c", "abc", False, "5.6 a*b?c needs ? char");
   Expect ("*?*", "a", True,      "5.7 *?* one char");
   Expect ("*?*", "", False,      "5.8 *?* rejects empty");
   Expect ("?*?", "aba", True,    "5.9 ?*? three");
   Expect ("?*?", "a", False,     "5.10 ?*? rejects one");

   ---------------------------------------------------------------------
   Section ("6. Consecutive stars");
   ---------------------------------------------------------------------
   Expect ("**", "xyz", True,     "6.1 ** any");
   Expect ("a**b", "ab", True,    "6.2 a**b empty middle");
   Expect ("a**b", "axxxb", True, "6.3 a**b filled");
   Expect ("***a***", "a", True,  "6.4 stars around a");
   Expect ("***a***", "xxayy", True, "6.5 stars around a filled");
   Expect ("*a*b*", "ab", True,   "6.6 *a*b* minimal");
   Expect ("*a*b*", "xaaybbz", True, "6.7 *a*b* filled");
   Expect ("*a*b*", "ba", False,  "6.8 *a*b* order wrong");

   ---------------------------------------------------------------------
   Section ("7. No-match / backtracking stress");
   ---------------------------------------------------------------------
   Expect ("a*b*c", "abx", False,     "7.1 missing c");
   Expect ("*abc", "abxabc", True,    "7.2 delayed suffix");
   Expect ("*abc", "abxabd", False,   "7.3 near-miss suffix");
   Expect ("a*a*a", "aaaa", True,     "7.4 repeated literal");
   Expect ("a*a*a", "aa", False,      "7.5 not enough a");
   Expect ("*a*b*c*", "xaybzc", True, "7.6 interleaved");
   Expect ("*a*b*c*", "cb", False,    "7.7 wrong order");
   Expect ("abcd", "abcde", False,    "7.8 extra suffix");
   Expect ("abc*", "abd", False,      "7.9 prefix fail with star");

   ---------------------------------------------------------------------
   Section ("8. Is_Match alias");
   ---------------------------------------------------------------------
   Check (Is_Match ("*foo*", "xfooy") = True,  "8.1 Is_Match positive");
   Check (Is_Match ("foo", "bar") = False,     "8.2 Is_Match negative");
   Check (Is_Match ("", "") = True,            "8.3 Is_Match empty");
   Check (Is_Match ("?", "Z") = Match ("?", "Z"), "8.4 alias equals Match");

   ---------------------------------------------------------------------
   Section ("9. Oracle cross-checks");
   ---------------------------------------------------------------------
   Expect_Oracle ("", "", "9.1");
   Expect_Oracle ("*", "hello", "9.2");
   Expect_Oracle ("a*b", "axb", "9.3");
   Expect_Oracle ("a*b", "ab", "9.4");
   Expect_Oracle ("a?c", "abc", "9.5");
   Expect_Oracle ("*foo*", "barfoobar", "9.6");
   Expect_Oracle ("???*", "xy", "9.7");
   Expect_Oracle ("***", "", "9.8");
   Expect_Oracle ("a*b*c", "aXbYc", "9.9");
   Expect_Oracle ("*a", "bbbb", "9.10");
   Expect_Oracle ("?*?", "xy", "9.11");
   Expect_Oracle ("x*y*z", "x--y--z", "9.12");
   Expect_Oracle ("abc", "abc", "9.13");
   Expect_Oracle ("abc", "Abc", "9.14");
   Expect_Oracle ("*?*?*", "ab", "9.15");

   ---------------------------------------------------------------------
   Section ("10. Wikipedia examples & extras");
   ---------------------------------------------------------------------
   Expect ("*foo*", "foo", True,           "10.1 wiki *foo*");
   Expect ("*foo*", "seafood", True,       "10.2 wiki-like contain");
   Expect ("mini*", "mini", True,          "10.3 wiki mini*");
   Expect ("???*", "cat", True,            "10.4 wiki ???*");
   Expect ("???*", "me", False,            "10.5 wiki ???* short");
   Expect ("file?.txt", "file1.txt", True, "10.6 glob-like");
   Expect ("file?.txt", "file12.txt", False, "10.7 glob-like reject");
   Expect ("*.*", "a.b", True,             "10.8 star-dot-star");
   Expect ("*.*", "abc", False,            "10.9 needs dot");
   Expect ("*", "*", True,                 "10.10 text is star char");

   New_Line;
   Put_Line ("Results: " & Pass_Count'Image & " PASS, "
             & Fail_Count'Image & " FAIL");

   if Fail_Count /= 0 then
      raise Program_Error with "test failures present";
   end if;
end Tests;
