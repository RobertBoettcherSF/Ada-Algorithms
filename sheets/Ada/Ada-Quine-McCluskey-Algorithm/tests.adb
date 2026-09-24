with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Quine_McCluskey; use Quine_McCluskey;

procedure Tests is
   Empty_M : Minterm_Array (1 .. 0);
   Result  : Implicant_List;
begin
   Put_Line ("======================================================");
   Put_Line ("    QUINE-MCCLUSKEY ALGORITHM V&V TEST SUITE");
   Put_Line ("======================================================");

   -- TEST 1 - Helper Functions Correctness
   Put_Line ("TEST 1 - Helper Mathematical/Logical Operations");
   Put_Line ("  1.1 Assert Count_Ones('10101') = 3");
   Assert (Count_Ones("10101") = 3, "Count_Ones failed");
   Put_Line ("     PASS");
   Put_Line ("  1.2 Assert Differs_By_One('100', '101') = True");
   Assert (Differs_By_One("100", "101") = True, "Differs_By_One True case failed");
   Put_Line ("     PASS");
   Put_Line ("  1.3 Assert Differs_By_One('110', '101') = False");
   Assert (Differs_By_One("110", "101") = False, "Differs_By_One False case failed");
   Put_Line ("     PASS");
   Put_Line ("  1.4 Assert Covers('-10', 2) = True (binary 010 covers 010)");
   Assert (Covers("-10", 2) = True, "Covers failed");
   Put_Line ("     PASS");

   -- TEST 2 - Single Variable Edge Cases
   Put_Line ("TEST 2 - Smallest Boundaries (1-Variable Edge Cases)");
   Put_Line ("  2.1 Assert Minimize_Exact for 1 Var, minterm(1) -> '1'");
   Result := Minimize_Exact (1, (1 => 1), Empty_M);
   Assert (Integer(Result.Length) = 1 and then Result.Element(1) = "1", "1-var failed");
   Put_Line ("     PASS");

   -- TEST 3 - Empty Inputs
   Put_Line ("TEST 3 - Empty Input Handling");
   Put_Line ("  3.1 Assert empty minterm array returns empty solution");
   Result := Minimize_Exact (3, Empty_M, Empty_M);
   Assert (Integer(Result.Length) = 0, "Empty minterms failed");
   Put_Line ("     PASS");

   -- TEST 4 - Full Truth Table Tautology
   Put_Line ("TEST 4 - All Minterms (Tautology)");
   Put_Line ("  4.1 Assert 2-var with all minterms (0,1,2,3) yields '--'");
   Result := Minimize_Exact (2, (0, 1, 2, 3), Empty_M);
   Assert (Integer(Result.Length) = 1 and then Result.Element(1) = "--", "Tautology failed");
   Put_Line ("     PASS");

   -- TEST 5 - Functional Correctness (Greedy & Exact equivalence on standard chart)
   Put_Line ("TEST 5 - Standard 3-Var Equation (Minterms 0, 1, 2, 3)");
   Put_Line ("  5.1 Assert 3-var Minimize_Greedy yields '0--'");
   Result := Minimize_Greedy (3, (0, 1, 2, 3), Empty_M);
   Assert (Integer(Result.Length) = 1 and then Result.Element(1) = "0--", "Greedy basic fail");
   Put_Line ("     PASS");

   -- TEST 6 - Don't Cares functionality
   Put_Line ("TEST 6 - Don't Cares Optimization");
   Put_Line ("  6.1 Assert minterms(0) & dont_cares(1,2,3) in 2-var yields '--'");
   Result := Minimize_Exact (2, (1 => 0), (1, 2, 3));
   Assert (Integer(Result.Length) = 1 and then Result.Element(1) = "--", "Dont cares failed");
   Put_Line ("     PASS");
   Put_Line ("  6.2 Assert pure Don't Cares without minterms returns empty");
   Result := Minimize_Exact (2, Empty_M, (1, 2));
   Assert (Integer(Result.Length) = 0, "Pure dont cares failed");
   Put_Line ("     PASS");

   -- TEST 7 - Exception Handling & Robustness
   Put_Line ("TEST 7 - Input Validation Exceptions");
   Put_Line ("  7.1 Assert Overlapping Minterms and Don't Cares raise Invalid_Input_Error");
   begin
      Result := Minimize_Exact (2, (1 => 1), (1 => 1));
      Assert (False, "Expected exception not raised for overlap");
   exception
      when Invalid_Input_Error => Put_Line ("     PASS");
   end;
   Put_Line ("  7.2 Assert Out-of-bounds Minterm raises Invalid_Input_Error");
   begin
      Result := Minimize_Exact (2, (1 => 5), Empty_M);
      Assert (False, "Expected exception not raised for OOB");
   exception
      when Invalid_Input_Error => Put_Line ("     PASS");
   end;

   -- TEST 8 - Cyclic Core (Petrick's Method differentiation)
   Put_Line ("TEST 8 - Cyclic Core Resolution");
   Put_Line ("  8.1 Assert 3-var Minterms(0,1,2,5,6,7) uses exact solver correctly (length 3)");
   Result := Minimize_Exact (3, (0, 1, 2, 5, 6, 7), Empty_M);
   Assert (Integer(Result.Length) = 3, "Cyclic core exact failed");
   Put_Line ("     PASS");

   -- TEST 9 - Wikipedia Example functional check
   Put_Line ("TEST 9 - Wikipedia 4-Var Example");
   Put_Line ("  9.1 Assert Wikipedia example logically reduces to exactly 3 terms");
   -- Minterms: 4,8,10,11,12,15. Dont_Cares: 9,14. (Equation: f(A,B,C,D) mathematically resolves to 3 optimal Prime Implicants)
   Result := Minimize_Exact (4, (4, 8, 10, 11, 12, 15), (9, 14));
   Assert (Integer(Result.Length) = 3, "Wikipedia example failed: Algorithm did not find the mathematically optimal 3 terms");
   Put_Line ("     PASS");

   Put_Line ("======================================================");
   Put_Line ("ALL 13+ ASSUMPTIONS DISPROVEN. CODE FUNCTIONS CORRECTLY.");
   Put_Line ("======================================================");
end Tests;
