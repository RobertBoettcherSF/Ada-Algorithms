--  Standalone test suite for Matching_Wildcards (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Matching_Wildcards; use Matching_Wildcards;

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

   procedure Expect_Both
     (Pattern, Text : String;
      Wanted        : Boolean;
      Label         : String)
   is
      Got_K : constant Boolean := Match_Krauss (Pattern, Text);
      Got_D : constant Boolean := Match_DP (Pattern, Text);
      Got_M : constant Boolean := Match (Pattern, Text, Krauss);
      Got_N : constant Boolean := Match (Pattern, Text, DP);
   begin
      Check (Got_K = Wanted,
             Label & "  Krauss Pattern=""" & Pattern & """ Text=""" & Text
             & """ → " & (if Wanted then "True" else "False"));
      Check (Got_D = Wanted,
             Label & "  DP     Pattern=""" & Pattern & """ Text=""" & Text
             & """ → " & (if Wanted then "True" else "False"));
      Check (Got_K = Got_D,
             Label & "  agree Krauss=DP");
      Check (Got_M = Got_K and then Got_N = Got_D,
             Label & "  dispatcher agrees");
   end Expect_Both;

   procedure Expect_Agree
     (Pattern, Text : String;
      Label         : String)
   is
      Got_K : constant Boolean := Match_Krauss (Pattern, Text);
      Got_D : constant Boolean := Match_DP (Pattern, Text);
   begin
      Check (Got_K = Got_D,
             Label & "  agree Pattern=""" & Pattern
             & """ Text=""" & Text
             & """ → " & (if Got_K then "True" else "False"));
   end Expect_Agree;

begin
   Put_Line ("Matching_Wildcards test suite");
   Put_Line ("=============================");

   ---------------------------------------------------------------------
   Section ("1. Empty pattern / empty text");
   ---------------------------------------------------------------------
   Expect_Both ("", "", True,  "1.1 empty matches empty");
   Expect_Both ("", "a", False, "1.2 empty does not match non-empty");
   Expect_Both ("*", "", True,  "1.3 star matches empty text");
   Expect_Both ("**", "", True, "1.4 consecutive stars match empty");
   Expect_Both ("?", "", False, "1.5 ? does not match empty");
   Expect_Both ("a", "", False, "1.6 literal does not match empty");

   ---------------------------------------------------------------------
   Section ("2. Literals (case-sensitive)");
   ---------------------------------------------------------------------
   Expect_Both ("abc", "abc", True,  "2.1 exact literal");
   Expect_Both ("abc", "abd", False, "2.2 mismatch last char");
   Expect_Both ("abc", "ab", False,  "2.3 text too short");
   Expect_Both ("ab", "abc", False,  "2.4 text too long");
   Expect_Both ("Abc", "abc", False, "2.5 case-sensitive mismatch");
   Expect_Both ("ABC", "ABC", True,  "2.6 uppercase exact");

   ---------------------------------------------------------------------
   Section ("3. Single '?' wildcard");
   ---------------------------------------------------------------------
   Expect_Both ("?", "a", True,   "3.1 ? matches one");
   Expect_Both ("?", "", False,   "3.2 ? rejects empty");
   Expect_Both ("?", "ab", False, "3.3 ? rejects two");
   Expect_Both ("??", "ab", True, "3.4 ?? matches two");
   Expect_Both ("a?c", "abc", True,  "3.5 a?c middle");
   Expect_Both ("a?c", "aXc", True,  "3.6 a?c any middle");
   Expect_Both ("a?c", "ac", False,  "3.7 a?c needs middle");

   ---------------------------------------------------------------------
   Section ("4. Single '*' wildcard");
   ---------------------------------------------------------------------
   Expect_Both ("*", "anything", True, "4.1 * matches any");
   Expect_Both ("*", "", True,         "4.2 * matches empty");
   Expect_Both ("a*", "a", True,       "4.3 a* prefix only");
   Expect_Both ("a*", "abc", True,     "4.4 a* prefix longer");
   Expect_Both ("a*", "b", False,      "4.5 a* wrong prefix");
   Expect_Both ("*c", "c", True,       "4.6 *c suffix only");
   Expect_Both ("*c", "abc", True,     "4.7 *c suffix longer");
   Expect_Both ("*c", "abd", False,    "4.8 *c wrong suffix");
   Expect_Both ("*foo*", "foo", True,  "4.9 *foo* exact");
   Expect_Both ("*foo*", "xfooy", True,"4.10 *foo* surround");
   Expect_Both ("*foo*", "fo", False,  "4.11 *foo* missing");
   Expect_Both ("mini*", "mini", True, "4.12 mini* exact");
   Expect_Both ("mini*", "minicomputer", True, "4.13 mini* longer");

   ---------------------------------------------------------------------
   Section ("5. Mixed '*' and '?'");
   ---------------------------------------------------------------------
   Expect_Both ("a*b?c", "axbyc", True,  "5.1 mixed match");
   Expect_Both ("a*b?c", "abc", False,   "5.2 mixed too short");
   Expect_Both ("?*", "a", True,         "5.3 ?* one char");
   Expect_Both ("?*", "", False,         "5.4 ?* needs one");
   Expect_Both ("*?", "xy", True,        "5.5 *? two");
   Expect_Both ("???*", "cat", True,     "5.6 ???* three+");
   Expect_Both ("???*", "me", False,     "5.7 ???* short");
   Expect_Both ("*?*?*", "ab", True,     "5.8 two chars min");

   ---------------------------------------------------------------------
   Section ("6. Consecutive stars / backtracking");
   ---------------------------------------------------------------------
   Expect_Both ("**", "xyz", True,              "6.1 ** any");
   Expect_Both ("***a***", "a", True,           "6.2 stars around a");
   Expect_Both ("***a***", "xxayy", True,       "6.3 stars around a longer");
   Expect_Both ("a*b*c", "aXbYc", True,         "6.4 multi-star");
   Expect_Both ("a*b*c", "ac", False,           "6.5 multi-star fail");
   Expect_Both ("da*da*da*", "daaadabadmanda", True, "6.6 Siler classic");
   Expect_Both ("*X*", "abcXdef", True,         "6.7 delayed X");
   Expect_Both ("*X*", "abcdef", False,         "6.8 no X");

   ---------------------------------------------------------------------
   Section ("7. Wikipedia / glob extras");
   ---------------------------------------------------------------------
   Expect_Both ("*foo*", "seafood", True,       "7.1 contain foo");
   Expect_Both ("file?.txt", "file1.txt", True, "7.2 glob-like");
   Expect_Both ("file?.txt", "file12.txt", False, "7.3 glob reject");
   Expect_Both ("*.*", "a.b", True,             "7.4 star-dot-star");
   Expect_Both ("*.*", "abc", False,            "7.5 needs dot");
   Expect_Both ("*", "*", True,                 "7.6 text is star char");
   Expect_Both ("x*y*z", "x--y--z", True,       "7.7 multi gap");
   Expect_Both ("?*?", "xy", True,              "7.8 ?*? two");

   ---------------------------------------------------------------------
   Section ("8. Cross-method agreement (extra pairs)");
   ---------------------------------------------------------------------
   Expect_Agree ("", "xyz", "8.1");
   Expect_Agree ("*", "hello", "8.2");
   Expect_Agree ("a*b", "axb", "8.3");
   Expect_Agree ("a*b", "ab", "8.4");
   Expect_Agree ("a?c", "abc", "8.5");
   Expect_Agree ("*foo*", "barfoobar", "8.6");
   Expect_Agree ("???*", "xy", "8.7");
   Expect_Agree ("***", "", "8.8");
   Expect_Agree ("a*b*c", "aXbYc", "8.9");
   Expect_Agree ("*a", "bbbb", "8.10");
   Expect_Agree ("abc", "Abc", "8.11");
   Expect_Agree ("*?*?*", "a", "8.12");
   Expect_Agree ("??*", "ab", "8.13");
   Expect_Agree ("a*a*a*", "aaaaaa", "8.14");
   Expect_Agree ("*b*", "aaa", "8.15");

   ---------------------------------------------------------------------
   Section ("9. Taxonomy / dispatcher helpers");
   ---------------------------------------------------------------------
   Check (Method_Count = 2, "9.1 Method_Count = 2");
   Check (Method_Name (Krauss) = "Krauss", "9.2 Method_Name Krauss");
   Check (Method_Name (DP) = "DP", "9.3 Method_Name DP");
   Check (Describe (Krauss)'Length > 0, "9.4 Describe Krauss non-empty");
   Check (Describe (DP)'Length > 0, "9.5 Describe DP non-empty");
   Check (Is_Match ("*foo*", "seafood") = True, "9.6 Is_Match alias");
   Check (Is_Match ("abc", "Abc") = False, "9.7 Is_Match case");
   Check (Match ("mini*", "minicomputer") = True, "9.8 default Match");

   New_Line;
   Put_Line ("Results: " & Pass_Count'Image & " PASS, "
             & Fail_Count'Image & " FAIL");

   if Fail_Count /= 0 then
      raise Program_Error with "test failures present";
   end if;
end Tests;
