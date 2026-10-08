--  Standalone test suite for Aho_Corasick (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Aho_Corasick; use Aho_Corasick;

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

   function Same_Matches (A, B : Match_List) return Boolean is
   begin
      if A'Length /= B'Length then
         return False;
      end if;
      for I in A'Range loop
         declare
            X : constant Match := A (I);
            Y : constant Match := B (I - A'First + B'First);
         begin
            if X.Pattern_Index /= Y.Pattern_Index
              or else X.Start_Position /= Y.Start_Position
              or else X.End_Position /= Y.End_Position
            then
               return False;
            end if;
         end;
      end loop;
      return True;
   end Same_Matches;

   function Has_Match
     (M              : Match_List;
      Pattern_Index  : Positive;
      Start_Position : Positive;
      End_Position   : Positive) return Boolean
   is
   begin
      for I in M'Range loop
         if M (I).Pattern_Index = Pattern_Index
           and then M (I).Start_Position = Start_Position
           and then M (I).End_Position = End_Position
         then
            return True;
         end if;
      end loop;
      return False;
   end Has_Match;

   function Build_Raises (Pats : Pattern_Array) return Boolean is
   begin
      declare
         Unused : constant Automaton := Build (Pats);
         pragma Unreferenced (Unused);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Build_Raises;

   function Search_Raises (A : Automaton; Text : String) return Boolean is
   begin
      declare
         Unused : constant Match_List := Search (A, Text);
         pragma Unreferenced (Unused);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Search_Raises;

   function Naive_Raises
     (Pats : Pattern_Array;
      Text : String) return Boolean
   is
   begin
      declare
         Unused : constant Match_List := Naive_Search (Pats, Text);
         pragma Unreferenced (Unused);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Naive_Raises;

   procedure Expect_Agree
     (Pats  : Pattern_Array;
      Text  : String;
      Label : String)
   is
      A : constant Automaton := Build (Pats);
      S : constant Match_List := Search (A, Text);
      N : constant Match_List := Naive_Search (Pats, Text);
   begin
      Check (Same_Matches (S, N), Label & " AC=naive");
   end Expect_Agree;

   Classic : constant Pattern_Array := Patterns ("he", "she", "his", "hers");
   Wiki    : constant Pattern_Array :=
     Patterns ("a", "ab", "bab", "bc", "bca", "c", "caa");

begin
   Put_Line ("Aho_Corasick test suite");
   Put_Line ("=======================");

   ---------------------------------------------------------------------
   Section ("1. Classic he/she/his/hers on ushers");
   ---------------------------------------------------------------------
   declare
      A : constant Automaton := Build (Classic);
      M : constant Match_List := Search (A, "ushers");
   begin
      Check (Pattern_Count (A) = 4, "classic pattern count");
      Check (Node_Count (A) > 1, "classic has trie nodes");
      Check (Pattern_Length (A, 1) = 2, "len he");
      Check (Pattern_Length (A, 2) = 3, "len she");
      Check (Pattern_Length (A, 3) = 3, "len his");
      Check (Pattern_Length (A, 4) = 4, "len hers");
      --  ushers: she@2..4, he@3..4, hers@3..6
      Check (M'Length = 3, "ushers match count = 3");
      Check (Has_Match (M, 2, 2, 4), "she at 2..4");
      Check (Has_Match (M, 1, 3, 4), "he at 3..4 (suffix of she)");
      Check (Has_Match (M, 4, 3, 6), "hers at 3..6");
      Check (Same_Matches (M, Naive_Search (Classic, "ushers")),
             "ushers AC=naive");
   end;
   Expect_Agree (Classic, "ushers", "ushers");
   Expect_Agree (Classic, "he", "he alone");
   Expect_Agree (Classic, "she", "she alone");
   Expect_Agree (Classic, "his", "his alone");
   Expect_Agree (Classic, "hers", "hers alone");
   Expect_Agree (Classic, "she hers his he", "mixed phrase");

   ---------------------------------------------------------------------
   Section ("2. No match / empty text");
   ---------------------------------------------------------------------
   declare
      A : constant Automaton := Build (Classic);
      M : constant Match_List := Search (A, "xyz");
      E : constant Match_List := Search (A, "");
   begin
      Check (M'Length = 0, "no match xyz");
      Check (E'Length = 0, "empty text → no matches");
   end;
   Expect_Agree (Classic, "", "empty text agree");
   Expect_Agree (Classic, "xyz", "xyz agree");
   Expect_Agree (Classic, "abcdefg", "abcdefg agree");

   ---------------------------------------------------------------------
   Section ("3. Single pattern reduces to expected");
   ---------------------------------------------------------------------
   declare
      Single : constant Pattern_Array := Patterns ("hello");
      A      : constant Automaton := Build (Single);
      M1     : constant Match_List := Search (A, "hello");
      M2     : constant Match_List := Search (A, "say hello there hello");
      M3     : constant Match_List := Search (A, "hell");
   begin
      Check (Pattern_Count (A) = 1, "single pattern count");
      Check (M1'Length = 1 and then M1 (1).Start_Position = 1
             and then M1 (1).End_Position = 5
             and then M1 (1).Pattern_Index = 1,
             "hello = text");
      Check (M2'Length = 2, "hello twice in phrase");
      Check (Has_Match (M2, 1, 5, 9), "first hello at 5..9");
      Check (Has_Match (M2, 1, 17, 21), "second hello at 17..21");
      Check (M3'Length = 0, "hell prefix → no match");
   end;
   Expect_Agree (Patterns ("hello"), "say hello there hello", "hello phrase");
   Expect_Agree (Patterns ("a"), "banana", "a in banana");
   Expect_Agree (Patterns ("abc"), "abcabcabc", "abc repeats");

   ---------------------------------------------------------------------
   Section ("4. Overlaps and suffix patterns (a/aa/aaa/aaaa)");
   ---------------------------------------------------------------------
   declare
      Over : constant Pattern_Array := Patterns ("a", "aa", "aaa", "aaaa");
      A    : constant Automaton := Build (Over);
      M    : constant Match_List := Search (A, "aaaa");
   begin
      --  ending at 1: a; at 2: a,aa; at 3: a,aa,aaa; at 4: a,aa,aaa,aaaa
      Check (M'Length = 10, "aaaa nested match count = 10");
      Check (Has_Match (M, 1, 1, 1), "a at 1");
      Check (Has_Match (M, 1, 4, 4), "a at 4");
      Check (Has_Match (M, 2, 3, 4), "aa at 3..4");
      Check (Has_Match (M, 3, 2, 4), "aaa at 2..4");
      Check (Has_Match (M, 4, 1, 4), "aaaa at 1..4");
      Check (Same_Matches (M, Naive_Search (Over, "aaaa")),
             "aaaa AC=naive");
   end;
   Expect_Agree (Patterns ("a", "aa", "aaa", "aaaa"), "aaaaaaaa", "eight a's");

   ---------------------------------------------------------------------
   Section ("5. Wikipedia dictionary on abccab");
   ---------------------------------------------------------------------
   declare
      A : constant Automaton := Build (Wiki);
      M : constant Match_List := Search (A, "abccab");
   begin
      Check (Has_Match (M, 1, 1, 1), "wiki a at 1");
      Check (Has_Match (M, 2, 1, 2), "wiki ab at 1..2");
      Check (Has_Match (M, 6, 3, 3), "wiki c at 3");
      Check (Has_Match (M, 4, 2, 3), "wiki bc at 2..3");
      Check (Has_Match (M, 6, 4, 4), "wiki c at 4");
      Check (Has_Match (M, 1, 5, 5), "wiki a at 5");
      Check (Has_Match (M, 2, 5, 6), "wiki ab at 5..6");
      Check (Same_Matches (M, Naive_Search (Wiki, "abccab")),
             "abccab AC=naive");
   end;
   Expect_Agree (Wiki, "abccab", "wiki abccab");
   Expect_Agree (Wiki, "bca", "wiki bca");
   Expect_Agree (Wiki, "caa", "wiki caa");
   Expect_Agree (Wiki, "babbcacaa", "wiki longer");

   ---------------------------------------------------------------------
   Section ("6. Overlapping multi-pattern (ana/ban/nan in banana)");
   ---------------------------------------------------------------------
   declare
      Dict : constant Pattern_Array := Patterns ("ana", "ban", "nan");
      A    : constant Automaton := Build (Dict);
      M    : constant Match_List := Search (A, "banana");
   begin
      Check (M'Length = 4, "banana match count = 4");
      Check (Has_Match (M, 2, 1, 3), "ban at 1..3");
      Check (Has_Match (M, 1, 2, 4), "ana at 2..4");
      Check (Has_Match (M, 3, 3, 5), "nan at 3..5");
      Check (Has_Match (M, 1, 4, 6), "ana at 4..6");
   end;
   Expect_Agree (Patterns ("ana", "ban", "nan"), "banana", "banana");
   Expect_Agree (Patterns ("ab", "ba"), "abababa", "abababa");

   ---------------------------------------------------------------------
   Section ("7. Invalid arguments");
   ---------------------------------------------------------------------
   declare
      Empty_List : Pattern_Array (1 .. 0);
   begin
      Check (Build_Raises (Empty_List), "empty pattern list");
      Check (Naive_Raises (Empty_List, "x"), "naive empty list");
   end;
   Check (Build_Raises (Patterns ("")), "empty individual pattern");
   Check (Naive_Raises (Patterns (""), "x"), "naive empty pattern");
   declare
      A : constant Automaton := Build (Classic);
   begin
      Check (not Search_Raises (A, ""), "empty text ok");
      Check (not Search_Raises (A, "ushers"), "normal search ok");
   end;
   declare
      Ok_Idx : Boolean := False;
      Bad    : Boolean := False;
      A      : constant Automaton := Build (Classic);
   begin
      begin
         declare
            L : constant Positive := Pattern_Length (A, 1);
            pragma Unreferenced (L);
         begin
            Ok_Idx := True;
         end;
      exception
         when Invalid_Argument =>
            Ok_Idx := False;
      end;
      begin
         declare
            L : constant Positive := Pattern_Length (A, 99);
            pragma Unreferenced (L);
         begin
            Bad := False;
         end;
      exception
         when Invalid_Argument =>
            Bad := True;
      end;
      Check (Ok_Idx, "Pattern_Length (1) ok");
      Check (Bad, "Pattern_Length (99) raises");
   end;

   ---------------------------------------------------------------------
   Section ("8. Ordering: End_Position then Pattern_Index");
   ---------------------------------------------------------------------
   declare
      Over    : constant Pattern_Array := Patterns ("a", "aa");
      A       : constant Automaton := Build (Over);
      M       : constant Match_List := Search (A, "aaa");
      Ordered : Boolean := True;
   begin
      for I in M'First .. M'Last - 1 loop
         if M (I).End_Position > M (I + 1).End_Position
           or else
             (M (I).End_Position = M (I + 1).End_Position
              and then M (I).Pattern_Index > M (I + 1).Pattern_Index)
         then
            Ordered := False;
         end if;
      end loop;
      Check (Ordered, "matches sorted by end then pattern");
      Check (M'Length = 5, "aaa with a/aa → 5 matches");
   end;

   ---------------------------------------------------------------------
   Section ("9. Extra dictionary / text pairs vs naive");
   ---------------------------------------------------------------------
   Expect_Agree (Patterns ("x"), "xxxxx", "xxxxx");
   Expect_Agree (Patterns ("x"), "yyyyy", "no x");
   Expect_Agree (Classic, "hershehis", "hershehis");
   Expect_Agree (Classic, "HHH", "case sensitive miss");
   Expect_Agree (Patterns ("she", "he"), "she", "she before he order");
   Expect_Agree (Patterns ("he", "she"), "she", "he before she order");
   Expect_Agree (Wiki, "", "wiki empty text");
   Expect_Agree (Patterns ("abc", "a"), "ababa", "abc+a");
   Expect_Agree (Patterns ("ban"), "bananas", "bananas single");
   Expect_Agree (Patterns ("a", "ab", "ba"), "abab", "a/ab/ba");

   ---------------------------------------------------------------------
   Section ("10. Start/End consistency");
   ---------------------------------------------------------------------
   declare
      A  : constant Automaton := Build (Classic);
      M  : constant Match_List := Search (A, "ushers");
      Ok : Boolean := True;
   begin
      for I in M'Range loop
         declare
            L : constant Positive := Pattern_Length (A, M (I).Pattern_Index);
         begin
            if M (I).End_Position - M (I).Start_Position + 1 /= L then
               Ok := False;
            end if;
         end;
      end loop;
      Check (Ok, "start/end span equals pattern length");
   end;

   New_Line;
   Put_Line
     ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image & " FAIL");
   if Fail_Count /= 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
