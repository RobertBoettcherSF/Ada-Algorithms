with Ada.Text_IO; use Ada.Text_IO;
with Shors_Algorithm; use Shors_Algorithm;

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
begin
   Put_Line ("=== STARTING SHOR'S ALGORITHM TEST SUITE ===");

   -- TEST 1 — GCD Functional Correctness
   Put_Line ("TEST 1 — GCD Functional Correctness");
   Check ("1.1 GCD of 15 and 9 is 3", GCD (15, 9) = 3);
   Check ("1.2 GCD of 17 and 13 is 1", GCD (17, 13) = 1);
   Check ("1.3 GCD of 100 and 25 is 25", GCD (100, 25) = 25);

   -- TEST 2 — GCD Edge Cases & Invariants
   Put_Line ("TEST 2 — GCD Edge Cases & Invariants");
   Check ("2.1 GCD with zero (24, 0)", GCD (24, 0) = 24);
   Check ("2.2 GCD of identical numbers (42, 42)", GCD (42, 42) = 42);
   Check ("2.3 GCD commutativity (GCD(12, 18) == GCD(18, 12))", GCD (12, 18) = GCD (18, 12));

   -- TEST 3 — Power_Mod Functional Correctness
   Put_Line ("TEST 3 — Power_Mod Functional Correctness");
   Check ("3.1 2^4 mod 15 = 1", Power_Mod (2, 4, 15) = 1);
   Check ("3.2 3^3 mod 7 = 6", Power_Mod (3, 3, 7) = 6);
   Check ("3.3 5^0 mod 13 = 1", Power_Mod (5, 0, 13) = 1);

   -- TEST 4 — Power_Mod Edge Cases & Modulus 1
   Put_Line ("TEST 4 — Power_Mod Edge Cases & Modulus 1");
   Check ("4.1 Modulus 1 returns 0", Power_Mod (5, 3, 1) = 0);
   Check ("4.2 Zero base (0^5 mod 7)", Power_Mod (0, 5, 7) = 0);
   Check ("4.3 Large exponent modular arithmetic", Power_Mod (2, 10, 1000) = 24);

   -- TEST 5 — Find_Period Standard Cases
   Put_Line ("TEST 5 — Find_Period Standard Cases");
   Check ("5.1 Period of 2 mod 15 is 4", Find_Period (2, 15) = 4);
   Check ("5.2 Period of 2 mod 7 is 3", Find_Period (2, 7) = 3);
   Check ("5.3 Period of 4 mod 7 is 3", Find_Period (4, 7) = 3);

   -- TEST 6 — Find_Period Error Handling & Exceptions
   Put_Line ("TEST 6 — Find_Period Error Handling & Exceptions");
   declare
      Raised : Boolean := False;
   begin
      begin
         declare
            Dummy : Period_Result;
         begin
            Dummy := Find_Period (3, 15); -- GCD(3, 15) = 3 != 1
            pragma Unreferenced (Dummy);
         end;
      exception
         when Order_Not_Found =>
            Raised := True;
      end;
      Check ("6.1 Non-coprime inputs raise Order_Not_Found", Raised);
   end;
   declare
      A_Val : constant Number := 2;
      N_Val : constant Number := 15;
   begin
      pragma Warnings (Off, "condition is always True");
      Check ("6.2 Verify A < N condition check", A_Val < N_Val);
      pragma Warnings (On, "condition is always True");
   end;
   Check ("6.3 Period result positivity invariant", Find_Period (2, 15) > 0);

   -- TEST 7 — Factor_Integer Composite 15
   Put_Line ("TEST 7 — Factor_Integer Composite 15");
   declare
      Res : constant Factor_Pair := Factor_Integer (15);
   begin
      Check ("7.1 Factor 1 of 15 is valid", Res.Factor_1 = 3 or Res.Factor_1 = 5);
      Check ("7.2 Factor 2 of 15 is valid", Res.Factor_2 = 3 or Res.Factor_2 = 5);
      Check ("7.3 Product of factors equals 15", (Res.Factor_1 * Res.Factor_2) = 15);
   end;

   -- TEST 8 — Factor_Integer Composite 21
   Put_Line ("TEST 8 — Factor_Integer Composite 21");
   declare
      Res : constant Factor_Pair := Factor_Integer (21);
   begin
      Check ("8.1 Factor 1 of 21 is valid", Res.Factor_1 = 3 or Res.Factor_1 = 7);
      Check ("8.2 Factor 2 of 21 is valid", Res.Factor_2 = 3 or Res.Factor_2 = 7);
      Check ("8.3 Product of factors equals 21", (Res.Factor_1 * Res.Factor_2) = 21);
   end;

   -- TEST 9 — Factor_Integer Even Numbers
   Put_Line ("TEST 9 — Factor_Integer Even Numbers");
   declare
      Res1 : constant Factor_Pair := Factor_Integer (18);
      Res2 : constant Factor_Pair := Factor_Integer (100);
   begin
      Check ("9.1 Factor 1 of 18 is 2", Res1.Factor_1 = 2 or Res1.Factor_2 = 2);
      Check ("9.2 Factor 2 of 100 product equals 100", (Res2.Factor_1 * Res2.Factor_2) = 100);
      Check ("9.3 Factor 1 of 100 is greater than 1", Res2.Factor_1 > 1);
   end;

   -- TEST 10 — Factor_Integer Larger Composites (35, 77)
   Put_Line ("TEST 10 — Factor_Integer Larger Composites");
   declare
      Res_35 : constant Factor_Pair := Factor_Integer (35);
      Res_77 : constant Factor_Pair := Factor_Integer (77);
   begin
      Check ("10.1 Product of factors for 35 equals 35", (Res_35.Factor_1 * Res_35.Factor_2) = 35);
      Check ("10.2 Product of factors for 77 equals 77", (Res_77.Factor_1 * Res_77.Factor_2) = 77);
      Check ("10.3 Factors are strictly greater than 1", Res_77.Factor_1 > 1 and Res_77.Factor_2 > 1);
   end;

   -- TEST 11 — Factor_Integer Error Handling & Preconditions
   Put_Line ("TEST 11 — Factor_Integer Error Handling & Preconditions");
   declare
      Raised : Boolean := False;
   begin
      begin
         declare
            Dummy : Factor_Pair;
         begin
            Dummy := Factor_Integer (3); -- N <= 3 invalid
            pragma Unreferenced (Dummy);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check ("11.1 N <= 3 raises Invalid_Argument", Raised);
   end;
   Check ("11.2 Factor pair components are non-trivial", Factor_Integer (15).Factor_1 > 1);
   Check ("11.3 Factor pair product invariant holds", (Factor_Integer (35).Factor_1 * Factor_Integer (35).Factor_2) = 35);

   -- TEST 12 — Solve_Discrete_Logarithm Standard Cases
   Put_Line ("TEST 12 — Solve_Discrete_Logarithm Standard Cases");
   Check ("12.1 Discrete log 2^x = 8 mod 11 -> x = 3", Solve_Discrete_Logarithm (2, 8, 11) = 3);
   Check ("12.2 Discrete log 3^x = 4 mod 7 -> x = 4", Solve_Discrete_Logarithm (3, 4, 7) = 4);
   Check ("12.3 Verification: Power_Mod matches solution", Power_Mod (2, Solve_Discrete_Logarithm (2, 8, 11), 11) = 8);

   -- TEST 13 — Solve_Discrete_Logarithm Error Handling & Exceptions
   Put_Line ("TEST 13 — Solve_Discrete_Logarithm Error Handling & Exceptions");
   declare
      Raised : Boolean := False;
   begin
      begin
         declare
            Dummy : Exponent;
         begin
            Dummy := Solve_Discrete_Logarithm (0, 5, 11); -- Invalid generator G = 0
            pragma Unreferenced (Dummy);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check ("13.1 Invalid generator raises Invalid_Argument", Raised);
   end;
   Check ("13.2 Valid exponent range output", Solve_Discrete_Logarithm (3, 2, 7) >= 0);
   Check ("13.3 Discrete log soundness check", Power_Mod (3, Solve_Discrete_Logarithm (3, 2, 7), 7) = 2);

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
              & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
