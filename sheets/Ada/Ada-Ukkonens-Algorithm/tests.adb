with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Ukkonen; use Ukkonen;

procedure Tests is
   Tree : Suffix_Tree;
begin
   Put_Line ("=====================================");
   Put_Line (" UKKONEN'S ALGORITHM - V&V TEST SUITE");
   Put_Line ("=====================================");
   Put_Line ("Assuming code is broken. Tests PASS if assumptions are disproven.");
   New_Line;

   -- TEST 1 - Functional Correctness (Single character)
   Put_Line ("TEST 1 - Single Character Tree");
   Put_Line ("  1.1 Assert tree builds for 'A'");
   Tree := Build_Suffix_Tree ("A");
   Put_Line ("  1.2 Assert tree contains 'A'");
   Assert (Contains_Substring (Tree, "A"), "Failed to find single char");
   Put_Line ("      PASS");

   -- TEST 2 - Empty String Edge Case
   Put_Line ("TEST 2 - Empty String Handling");
   Put_Line ("  2.1 Assert empty tree raises Invalid_Input");
   begin
      declare
         Empty_Tree : Suffix_Tree := Build_Suffix_Tree ("");
      begin
         Assert (False, "Expected Invalid_Input not raised");
      end;
   exception
      when Invalid_Input =>
         Put_Line ("      PASS");
   end;

   -- TEST 3 - Simple Substring Matches
   Put_Line ("TEST 3 - Simple Search in 'abc'");
   Tree := Build_Suffix_Tree ("abc");
   Put_Line ("  3.1 Assert contains prefix 'ab'");
   Assert (Contains_Substring (Tree, "ab"), "Failed to find 'ab'");
   Put_Line ("  3.2 Assert contains suffix 'bc'");
   Assert (Contains_Substring (Tree, "bc"), "Failed to find 'bc'");
   Put_Line ("  3.3 Assert contains inner 'b'");
   Assert (Contains_Substring (Tree, "b"), "Failed to find 'b'");
   Put_Line ("      PASS");

   -- TEST 4 - Non-existent Substrings
   Put_Line ("TEST 4 - Negative Substring Checking");
   Put_Line ("  4.1 Assert does NOT contain 'x'");
   Assert (not Contains_Substring (Tree, "x"), "Falsely found 'x'");
   Put_Line ("  4.2 Assert does NOT contain 'abd'");
   Assert (not Contains_Substring (Tree, "abd"), "Falsely found 'abd'");
   Put_Line ("      PASS");

   -- TEST 5 - Empty Substring Validation
   Put_Line ("TEST 5 - Empty Substring Edge Case");
   Put_Line ("  5.1 Assert contains empty string '' inside 'abc'");
   Assert (Contains_Substring (Tree, ""), "Failed empty string inclusion");
   Put_Line ("      PASS");

   -- TEST 6 - Repeated Characters
   Put_Line ("TEST 6 - Monotonic Repetitions ('aaaa')");
   Tree := Build_Suffix_Tree ("aaaa");
   Put_Line ("  6.1 Assert contains 'aa'");
   Assert (Contains_Substring (Tree, "aa"), "Failed 'aa' in 'aaaa'");
   Put_Line ("  6.2 Assert contains 'aaaa'");
   Assert (Contains_Substring (Tree, "aaaa"), "Failed 'aaaa' in 'aaaa'");
   Put_Line ("  6.3 Assert does NOT contain 'aaaaa' (overflow)");
   Assert (not Contains_Substring (Tree, "aaaaa"), "Falsely found 'aaaaa'");
   Put_Line ("      PASS");

   -- TEST 7 - Suffix Link Verification (Complex Patterns)
   Put_Line ("TEST 7 - Complex Patterns & Internal Suffix Links");
   Tree := Build_Suffix_Tree ("abacabadabacaba");
   Put_Line ("  7.1 Assert contains 'bacaba'");
   Assert (Contains_Substring (Tree, "bacaba"), "Suffix link rule 2 failed");
   Put_Line ("  7.2 Assert contains 'dab'");
   Assert (Contains_Substring (Tree, "dab"), "Suffix link split rule failed");
   Put_Line ("      PASS");

   -- TEST 8 - Case Sensitivity
   Put_Line ("TEST 8 - Case Sensitivity Validation");
   Tree := Build_Suffix_Tree ("AdaProgramming");
   Put_Line ("  8.1 Assert 'Ada' succeeds");
   Assert (Contains_Substring (Tree, "Ada"), "Failed 'Ada'");
   Put_Line ("  8.2 Assert 'ada' fails (case mismatch)");
   Assert (not Contains_Substring (Tree, "ada"), "Failed case sensitivity check");
   Put_Line ("      PASS");

   -- TEST 9 - Long String (Performance/Memory Stress)
   Put_Line ("TEST 9 - Memory Stress Bounds (1000 chars)");
   declare
      Long_Str : String (1 .. 1000) := (others => 'x');
   begin
      Put_Line ("  9.1 Assert tree builds correctly for massive repeat");
      Tree := Build_Suffix_Tree (Long_Str);
      Put_Line ("  9.2 Assert valid internal fetch operates in limits");
      Assert (Contains_Substring (Tree, "xxxxx"), "Failed lookup in long string");
      Put_Line ("      PASS");
   end;

   -- TEST 10 - Wikipedia Example Test
   Put_Line ("TEST 10 - Wikipedia Standard String");
   Tree := Build_Suffix_Tree ("mississippi$");
   Put_Line ("  10.1 Assert contains 'issip'");
   Assert (Contains_Substring (Tree, "issip"), "Wikipedia example 'issip' failed");
   Put_Line ("  10.2 Assert contains 'pi$'");
   Assert (Contains_Substring (Tree, "pi$"), "Wikipedia example terminal failed");
   Put_Line ("      PASS");

   -- TEST 11 - Special Characters
   Put_Line ("TEST 11 - Special / Punctuation Characters");
   Tree := Build_Suffix_Tree ("Hello, World! 123");
   Put_Line ("  11.1 Assert contains ', '");
   Assert (Contains_Substring (Tree, ", "), "Failed punctuation tracking");
   Put_Line ("  11.2 Assert contains '123'");
   Assert (Contains_Substring (Tree, "123"), "Failed numerical characters");
   Put_Line ("      PASS");

   -- TEST 12 - Deep Split Edge Test
   Put_Line ("TEST 12 - Split Edge Exhaustive Misdirection");
   Tree := Build_Suffix_Tree ("cacao");
   Put_Line ("  12.1 Assert contains 'cao'");
   Assert (Contains_Substring (Tree, "cao"), "Misdirected split edge resolution");
   Put_Line ("  12.2 Assert DOES NOT contain 'cacaa'");
   Assert (not Contains_Substring (Tree, "cacaa"), "Improper boundary mapping");
   Put_Line ("      PASS");

   -- TEST 13 - Mid-Edge Failure Handling
   Put_Line ("TEST 13 - Mid-Edge Mismatch Resolution");
   Tree := Build_Suffix_Tree ("verification");
   Put_Line ("  13.1 Assert fails correctly when starting path matches but ends wrongly");
   Assert (not Contains_Substring (Tree, "verificX"), "Falsely validated mismatched tail");
   Put_Line ("      PASS");

   New_Line;
   Put_Line ("ALL TESTS EXECUTED AND PASSED.");
end Tests;
