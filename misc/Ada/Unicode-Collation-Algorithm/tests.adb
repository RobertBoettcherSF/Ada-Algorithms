-- tests.adb
-- Comprehensive Verification and Validation suite for UCA
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Unicode_Collation; use Unicode_Collation;

procedure Tests is
   Table : Character_Table := Get_Default_Table;
   Total_Tests : Integer := 0;
   Passed_Tests : Integer := 0;

   procedure Run_Assert (Condition : Boolean; Message : String) is
   begin
      Total_Tests := Total_Tests + 1;
      Put("      " & Message & " ... ");
      Assert (Condition, "FAILED: " & Message);
      Put_Line("PASS");
      Passed_Tests := Passed_Tests + 1;
   exception
      when Assertion_Error =>
         Put_Line("FAIL");
   end Run_Assert;

begin
   Put_Line("===============================================");
   Put_Line(" UCA V&V TEST SUITE (Assumes broken codebase)");
   Put_Line("===============================================");

   Put_Line("TEST 1 - Base Primary Level Comparison (L1)");
   Run_Assert (Compare_Standard("a", "b", Table) = Less, "1.1 Assert 'a' < 'b'");
   Run_Assert (Compare_Standard("b", "a", Table) = Greater, "1.2 Assert 'b' > 'a'");
   Run_Assert (Compare_Standard("a", "a", Table) = Equal, "1.3 Assert 'a' == 'a'");

   Put_Line("TEST 2 - Tertiary Level Comparison (Case - L3)");
   Run_Assert (Compare_Standard("a", "A", Table) = Less, "2.1 Lowercase < Uppercase in UCA default");
   Run_Assert (Compare_Standard("A", "a", Table) = Greater, "2.2 Uppercase > Lowercase");
   
   Put_Line("TEST 3 - Multi-level resolution");
   -- 'a' vs 'A': Primary is same. L1 evaluates equal. Defers to L3.
   Run_Assert (Compare_Standard("aa", "aA", Table) = Less, "3.1 Prefix tie breaks correctly at L3");

   Put_Line("TEST 4 - Length Asymmetry");
   Run_Assert (Compare_Standard("a", "ab", Table) = Less, "4.1 Shorter string evaluated Less");
   Run_Assert (Compare_Standard("abc", "ab", Table) = Greater, "4.2 Longer string evaluated Greater");

   Put_Line("TEST 5 - Empty String Edge Cases");
   Run_Assert (Compare_Standard("", "", Table) = Equal, "5.1 Empty == Empty");
   Run_Assert (Compare_Standard("", "a", Table) = Less, "5.2 Empty < Non-Empty");
   Run_Assert (Compare_Standard("a", "", Table) = Greater, "5.3 Non-Empty > Empty");

   Put_Line("TEST 6 - Standard Punctuation Handling (Ignored L1, Checked L3)");
   -- Primary weights for '-' are 0, so "a-b" and "ab" are equal at L1 and L2.
   -- At L3, '-' has weight. Thus "a-b" differs from "ab".
   Run_Assert (Compare_Standard("a-b", "ab", Table) /= Equal, "6.1 Standard: Punctuation is NOT completely ignored");

   Put_Line("TEST 7 - Variable Weighting (Ignore Punctuation Variant)");
   -- Here, '-' is forcefully zeroed out at all levels. "a-b" == "ab".
   Run_Assert (Compare_Ignore_Punctuation("a-b", "ab", Table) = Equal, "7.1 Ignore_Punct: Hyphen entirely ignored");
   Run_Assert (Compare_Ignore_Punctuation("a b", "ab", Table) = Equal, "7.2 Ignore_Punct: Space entirely ignored");
   Run_Assert (Compare_Ignore_Punctuation("a,b", "ab", Table) = Equal, "7.3 Ignore_Punct: Comma entirely ignored");

   Put_Line("TEST 8 - Tailoring (Locale Customization Variant)");
   declare
      -- Example: In some locales, 'z' might sort BEFORE 'a'
      Custom_Table : Character_Table := Table;
      Z_Weight : Collation_Weight := Table('a'); 
   begin
      Z_Weight.Primary := Z_Weight.Primary - 1; -- Make 'z' lighter than 'a'
      Custom_Table := Apply_Tailoring(Custom_Table, 'z', Z_Weight);
      
      Run_Assert (Compare_Standard("z", "a", Custom_Table) = Less, "8.1 Tailored: 'z' forced to sort before 'a'");
      Run_Assert (Compare_Standard("z", "a", Table) = Greater, "8.2 Standard: 'z' still sorts after 'a' normally");
   end;

   Put_Line("TEST 9 - Identical Strings Robustness");
   Run_Assert (Compare_Standard("hello-world", "hello-world", Table) = Equal, "9.1 Long string exact match");
   Run_Assert (Compare_Ignore_Punctuation("hello-world", "helloworld", Table) = Equal, "9.2 Long string punctuation ignored match");

   Put_Line("===============================================");
   Put_Line("Tests completed: " & Integer'Image(Passed_Tests) & " /" & Integer'Image(Total_Tests) & " PASSED.");
   
   if Total_Tests = Passed_Tests then
      Put_Line("CONCLUSION: Codebase assumed broken, but ALL ASSUMPTIONS DISPROVED.");
   else
      Put_Line("CONCLUSION: Codebase contains faults.");
   end if;
end Tests;
