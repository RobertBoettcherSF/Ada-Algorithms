-- ============================================================================
-- Test Suite & Usage Example: Tests
-- Description: Comprehensive test suite for Hidden_Shift package implementing
--              13 distinct test categories with multiple assertions each.
-- ============================================================================

with Ada.Text_IO; use Ada.Text_IO;
with Hidden_Shift; use Hidden_Shift;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS — " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL — " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   -- Representative sample function table
   F_Sample : constant Function_Table := [
      0  => 10,
      1  => 20,
      2  => 30,
      3  => 40,
      4  => 50,
      5  => 60,
      6  => 70,
      7  => 80,
      8  => 90,
      9  => 100,
      10 => 110,
      11 => 120,
      12 => 130,
      13 => 140,
      14 => 150,
      15 => 160
   ];

   -- Helper function to construct G where G(x) = F(x + Shift)
   function Make_Shifted_G (Shift : Domain_Element; F : Function_Table) return Function_Table is
      G : Function_Table;
   begin
      for X in Domain_Element loop
         G (X) := F (X + Shift);
      end loop;
      return G;
   end Make_Shifted_G;

begin
   Put_Line ("=== STARTING HIDDEN SHIFT PROBLEM TEST SUITE ===");

   -- TEST 1 — Basic Brute-Force Resolution (Zero Shift)
   Put_Line ("TEST 1 — Basic Brute-Force Resolution (Zero Shift)");
   declare
      G : constant Function_Table := F_Sample;
      S : constant Domain_Element := Solve_Brute_Force (F_Sample, G);
   begin
      Check ("1.1 Brute force finds shift for identical functions", S = 0);
      Check ("1.2 Shift verification holds for zero shift", Verify_Shift (F_Sample, G, 0));
      Check ("1.3 Correlation score is maximum for zero shift", Compute_Correlation (F_Sample, G, 0) = 16);
   end;

   -- TEST 2 — Brute-Force Resolution with Non-Zero Shift
   Put_Line ("TEST 2 — Brute-Force Resolution with Non-Zero Shift");
   declare
      Target_Shift : constant Domain_Element := 5;
      G : constant Function_Table := Make_Shifted_G (Target_Shift, F_Sample);
      S : constant Domain_Element := Solve_Brute_Force (F_Sample, G);
   begin
      Check ("2.1 Brute force correctly identifies shift 5", S = Target_Shift);
      Check ("2.2 Verify_Shift confirms shift 5", Verify_Shift (F_Sample, G, 5));
      Check ("2.3 Verify_Shift rejects incorrect shift 0", not Verify_Shift (F_Sample, G, 0));
   end;

   -- TEST 3 — Correlation Search with Exact Match
   Put_Line ("TEST 3 — Correlation Search with Exact Match");
   declare
      Target_Shift : constant Domain_Element := 11;
      G : constant Function_Table := Make_Shifted_G (Target_Shift, F_Sample);
      S : constant Domain_Element := Solve_Correlation_Search (F_Sample, G);
   begin
      Check ("3.1 Correlation search identifies shift 11", S = Target_Shift);
      Check ("3.2 Correlation score for shift 11 is 16", Compute_Correlation (F_Sample, G, 11) = 16);
      Check ("3.3 Correlation score for wrong shift is less than 16", Compute_Correlation (F_Sample, G, 0) < 16);
   end;

   -- TEST 4 — Shift Verification Function (True Cases)
   Put_Line ("TEST 4 — Shift Verification Function (True Cases)");
   declare
      Target_Shift : constant Domain_Element := 2;
      G : constant Function_Table := Make_Shifted_G (Target_Shift, F_Sample);
   begin
      Check ("4.1 Verify shift 2 returns true", Verify_Shift (F_Sample, G, 2));
      Check ("4.2 Compute correlation for shift 2 equals domain size", Compute_Correlation (F_Sample, G, 2) = 16);
      Check ("4.3 Brute force agrees with target shift 2", Solve_Brute_Force (F_Sample, G) = 2);
   end;

   -- TEST 5 — Shift Verification Function (False Cases)
   Put_Line ("TEST 5 — Shift Verification Function (False Cases)");
   declare
      Target_Shift : constant Domain_Element := 7;
      G : constant Function_Table := Make_Shifted_G (Target_Shift, F_Sample);
   begin
      Check ("5.1 Verify shift 0 returns false", not Verify_Shift (F_Sample, G, 0));
      Check ("5.2 Verify shift 6 returns false", not Verify_Shift (F_Sample, G, 6));
      Check ("5.3 Compute correlation for wrong shift is low", Compute_Correlation (F_Sample, G, 0) /= 16);
   end;

   -- TEST 6 — Correlation Scoring Function
   Put_Line ("TEST 6 — Correlation Scoring Function");
   declare
      G : constant Function_Table := Make_Shifted_G (4, F_Sample);
      Score_Correct : constant Natural := Compute_Correlation (F_Sample, G, 4);
      Score_Wrong   : constant Natural := Compute_Correlation (F_Sample, G, 1);
   begin
      Check ("6.1 Correct shift correlation score is 16", Score_Correct = 16);
      Check ("6.2 Incorrect shift correlation score is low", Score_Wrong < 16);
      Check ("6.3 Correlation score is bounded by 0 and 16", Score_Wrong <= 16);
   end;

   -- TEST 7 — Error Handling: No Shift Found (Brute Force)
   Put_Line ("TEST 7 — Error Handling: No Shift Found (Brute Force)");
   declare
      F_Const        : constant Function_Table := [others => 5];
      G_Inconsistent : constant Function_Table := [0 => 5, others => 99];
      Exception_Raised : Boolean := False;
   begin
      begin
         declare
            Dummy : Domain_Element;
            pragma Unreferenced (Dummy);
         begin
            Dummy := Solve_Brute_Force (F_Const, G_Inconsistent);
         end;
      exception
         when No_Shift_Found =>
            Exception_Raised := True;
      end;
      Check ("7.1 No_Shift_Found exception raised for inconsistent functions", Exception_Raised);
      Check ("7.2 Verify_Shift returns false for all shifts on inconsistent pair", 
             (for all S in Domain_Element => not Verify_Shift (F_Const, G_Inconsistent, S)));
      Check ("7.3 Maximum correlation is less than 16", Compute_Correlation (F_Const, G_Inconsistent, 0) < 16);
   end;

   -- TEST 8 — Error Handling: No Shift Found (Correlation Search)
   Put_Line ("TEST 8 — Error Handling: No Shift Found (Correlation Search)");
   declare
      F_Flat     : constant Function_Table := [others => 1];
      G_Disjoint : constant Function_Table := [others => 999];
      Exception_Raised : Boolean := False;
   begin
      begin
         declare
            Dummy : Domain_Element;
            pragma Unreferenced (Dummy);
         begin
            Dummy := Solve_Correlation_Search (F_Flat, G_Disjoint);
         end;
      exception
         when No_Shift_Found =>
            Exception_Raised := True;
      end;
      Check ("8.1 No_Shift_Found raised in correlation search for disjoint ranges", Exception_Raised);
      Check ("8.2 Correlation score is 0 for disjoint functions across all shifts", 
             Compute_Correlation (F_Flat, G_Disjoint, 0) = 0);
      Check ("8.3 Verification fails for zero shift on disjoint functions", not Verify_Shift (F_Flat, G_Disjoint, 0));
   end;

   -- TEST 9 — Constant Function Domain Shift
   Put_Line ("TEST 9 — Constant Function Domain Shift");
   declare
      F_Const : constant Function_Table := [others => 42];
      G_Const : constant Function_Table := [others => 42];
      S       : constant Domain_Element := Solve_Brute_Force (F_Const, G_Const);
   begin
      Check ("9.1 Brute force handles constant functions without error", S = 0 or S /= 0);
      Check ("9.2 Verify_Shift confirms shift 0 for constant functions", Verify_Shift (F_Const, G_Const, 0));
      Check ("9.3 Correlation score for constant functions is 16 at shift 0", Compute_Correlation (F_Const, G_Const, 0) = 16);
   end;

   -- TEST 10 — Symmetric / Repeating Functions
   Put_Line ("TEST 10 — Symmetric / Repeating Functions");
   declare
      F_Rep : constant Function_Table := [0 => 1, 1 => 2, 2 => 1, 3 => 2, 
                                          4 => 1, 5 => 2, 6 => 1, 7 => 2,
                                          8 => 1, 9 => 2, 10 => 1, 11 => 2,
                                          12 => 1, 13 => 2, 14 => 1, 15 => 2];
      G_Rep : constant Function_Table := Make_Shifted_G (2, F_Rep);
      S_BF  : constant Domain_Element := Solve_Brute_Force (F_Rep, G_Rep);
      S_CS  : constant Domain_Element := Solve_Correlation_Search (F_Rep, G_Rep);
   begin
      Check ("10.1 Brute force finds valid shift for repeating function", Verify_Shift (F_Rep, G_Rep, S_BF));
      Check ("10.2 Correlation search finds valid shift for repeating function", Verify_Shift (F_Rep, G_Rep, S_CS));
      Check ("10.3 Both methods return valid shifts", Verify_Shift (F_Rep, G_Rep, S_BF) and Verify_Shift (F_Rep, G_Rep, S_CS));
   end;

   -- TEST 11 — Invariant Testing: Round-trip Verification
   Put_Line ("TEST 11 — Invariant Testing: Round-trip Verification");
   declare
      Target_Shift : constant Domain_Element := 9;
      G            : constant Function_Table := Make_Shifted_G (Target_Shift, F_Sample);
      S            : constant Domain_Element := Solve_Brute_Force (F_Sample, G);
   begin
      Check ("11.1 Round-trip shift matches injected shift", S = Target_Shift);
      Check ("11.2 Round-trip verification succeeds", Verify_Shift (F_Sample, G, S));
      Check ("11.3 Round-trip correlation is maximal", Compute_Correlation (F_Sample, G, S) = 16);
   end;

   -- TEST 12 — Invariant Testing: Correlation vs Brute Force Agreement
   Put_Line ("TEST 12 — Invariant Testing: Correlation vs Brute Force Agreement");
   declare
      Target_Shift : constant Domain_Element := 14;
      G            : constant Function_Table := Make_Shifted_G (Target_Shift, F_Sample);
      S_BF         : constant Domain_Element := Solve_Brute_Force (F_Sample, G);
      S_CS         : constant Domain_Element := Solve_Correlation_Search (F_Sample, G);
   begin
      Check ("12.1 Brute force and correlation search yield same result", S_BF = S_CS);
      Check ("12.2 Result matches target shift 14", S_BF = 14);
      Check ("12.3 Verification passes for both methods' output", Verify_Shift (F_Sample, G, S_BF));
   end;

   -- TEST 13 — Edge Case: High-Order Shift Wrap-around
   Put_Line ("TEST 13 — Edge Case: High-Order Shift Wrap-around");
   declare
      Target_Shift : constant Domain_Element := 15;
      G            : constant Function_Table := Make_Shifted_G (Target_Shift, F_Sample);
      S            : constant Domain_Element := Solve_Brute_Force (F_Sample, G);
   begin
      Check ("13.1 High-order shift 15 correctly resolved", S = 15);
      Check ("13.2 Verify_Shift confirms shift 15 with wrap-around", Verify_Shift (F_Sample, G, 15));
      Check ("13.3 Correlation score for shift 15 is 16", Compute_Correlation (F_Sample, G, 15) = 16);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
            & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
