-- tests.adb
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Shortest_Common_Supersequence; use Shortest_Common_Supersequence;

procedure Tests is
   procedure Title (Txt : String) is begin Put_Line (""); Put_Line ("==== " & Txt & " ===="); end Title;
   procedure Step (Txt : String) is begin Put_Line ("  " & Txt); end Step;
   procedure Pass is begin Put_Line ("      PASS: Assumption disproven. Code verified."); end Pass;
   
   Arr_Mult : Unbounded_String_Array(1..3);
   Empty_Arr : Unbounded_String_Array(1..0);
begin
   Put_Line ("INITIALIZING TEST SUITE: Assuming code is non-functional. Proving otherwise...");

   Title ("TEST 1 - Functional Correctness (Length exact match)");
   Step ("1.1 Assert length of SCS('geek', 'eke') = 5");
   Assert (SCS_Length ("geek", "eke") = 5, "Failed basic SCS length");
   Pass;
   
   Title ("TEST 2 - Functional Correctness (String exact match)");
   Step ("2.1 Assert SCS('geek', 'eke') = 'geeke'");
   Assert (SCS_String ("geek", "eke") = "geeke", "Failed basic SCS string");
   Pass;
   
   Title ("TEST 3 - Disjoint Strings Boundary");
   Step ("3.1 Assert SCS('abc', 'def') concatenates strings (len=6)");
   Assert (SCS_Length ("abc", "def") = 6, "Disjoint length calculation failed");
   Step ("3.2 Assert string retains both independent components");
   Assert (SCS_String ("abc", "def") = "abcdef" or SCS_String("abc", "def") = "defabc", "Disjoint string layout failed");
   Pass;

   Title ("TEST 4 - Subsequence Strict Containment");
   Step ("4.1 Assert if Y in X, SCS = X");
   Assert (SCS_String ("programming", "gram") = "programming", "Subsequence failure");
   Pass;

   Title ("TEST 5 - Empty String Edge Case (First parameter)");
   Step ("5.1 Assert SCS('', 'abc') = 'abc'");
   Assert (SCS_String ("", "abc") = "abc", "Empty string (left) handling failed");
   Pass;

   Title ("TEST 6 - Empty String Edge Case (Second parameter)");
   Step ("6.1 Assert SCS('xyz', '') = 'xyz'");
   Assert (SCS_String ("xyz", "") = "xyz", "Empty string (right) handling failed");
   Pass;

   Title ("TEST 7 - Total Emptiness Boundary");
   Step ("7.1 Assert SCS('', '') = ''");
   Assert (SCS_Length ("", "") = 0, "Double empty length failed");
   Assert (SCS_String ("", "") = "", "Double empty string failed");
   Pass;

   Title ("TEST 8 - Complex DNA Sequence Overlap");
   Step ("8.1 Assert SCS('AGGTAB', 'GXTXAYB') yields valid 9-char supersequence");
   -- There are multiple optimal shortest common supersequences of length 9 for this input.
   Assert (SCS_String ("AGGTAB", "GXTXAYB") = "AGXGTXAYB" or SCS_String ("AGGTAB", "GXTXAYB") = "AGGXTXAYB", "Complex DNA matching failed");
   Pass;
   
   Title ("TEST 9 - Identity Relation");
   Step ("9.1 Assert SCS(X, X) = X");
   Assert (SCS_String ("ada2012", "ada2012") = "ada2012", "Identity relation failed");
   Pass;

   Title ("TEST 10 - Case Sensitivity Restriction");
   Step ("10.1 Assert SCS('A', 'a') != 'A' (should be 'Aa' or 'aA')");
   Assert (SCS_String ("A", "a") = "Aa" or SCS_String ("A", "a") = "aA", "Case sensitivity failure");
   Pass;

   Title ("TEST 11 - NP-Hard Approximation Validation (k-strings)");
   Step ("11.1 Assert greedy iteration of ['abc', 'cde', 'efg'] yields 'abcdefg'");
   Arr_Mult(1) := To_Unbounded_String("abc");
   Arr_Mult(2) := To_Unbounded_String("cde");
   Arr_Mult(3) := To_Unbounded_String("efg");
   Assert (SCS_Multiple(Arr_Mult) = "abcdefg", "Multi-string greedy fold failed");
   Pass;

   Title ("TEST 12 - NP-Hard Approximation Bound: Subsumed array");
   Step ("12.1 Assert greedy iteration on identical strings yields one instance");
   Arr_Mult(1) := To_Unbounded_String("root");
   Arr_Mult(2) := To_Unbounded_String("root");
   Arr_Mult(3) := To_Unbounded_String("root");
   Assert (SCS_Multiple(Arr_Mult) = "root", "Subsumption on multi-array failed");
   Pass;

   Title ("TEST 13 - Exception Handling: Empty Array Constraint");
   Step ("13.1 Assert passing 0-length array raises Empty_Array_Error");
   begin
      declare
         Dummy : String := SCS_Multiple(Empty_Arr);
      begin
         Assert (False, "Expected exception was bypassed");
      end;
   exception
      when Empty_Array_Error =>
         Pass;
   end;

   Put_Line ("");
   Put_Line ("TEST RUN COMPLETE: 13/13 Pessimistic Assumptions Disproven. System Verified.");

end Tests;
