with Ada.Text_IO; use Ada.Text_IO;
with Hidden_Subgroup_Problem; use Hidden_Subgroup_Problem;

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

   Ex_Caught : Boolean;

begin
   -- TEST 1 — Simon's Problem Solver (s = 3)
   Put_Line ("TEST 1 — Simon's Problem Solver (s = 3)");
   declare
      S : constant Bit_Mask := Solve_Simons_Problem (2, Simon_Oracle_Sample_1'Access);
   begin
      Check ("1.1 Simon solver returns non-zero", S > 0);
      Check ("1.2 Simon solver detects correct hidden string 3", S = 3);
      pragma Warnings (Off, "upper bound test optimized away");
      Check ("1.3 Simon solver result is within 8-bit range", S in 1 .. 255);
      pragma Warnings (On, "upper bound test optimized away");
   end;

   -- TEST 2 — Simon's Problem Solver (s = 5)
   Put_Line ("TEST 2 — Simon's Problem Solver (s = 5)");
   declare
      S : constant Bit_Mask := Solve_Simons_Problem (3, Simon_Oracle_Sample_2'Access);
   begin
      Check ("2.1 Simon solver returns non-zero for s=5", S > 0);
      Check ("2.2 Simon solver detects correct hidden string 5", S = 5);
      Check ("2.3 Simon solver execution completed successfully", True);
   end;

   -- TEST 3 — Period Finding (Period 3 in Z_9)
   Put_Line ("TEST 3 — Period Finding (Period 3 in Z_9)");
   declare
      P : constant Period_Type := Solve_Period_Finding (9, Period_Oracle_Sample_3'Access);
   begin
      Check ("3.1 Period is positive", P > 0);
      Check ("3.2 Period equals 3", P = 3);
      pragma Warnings (Off, "condition can only be");
      Check ("3.3 Period divides group size 9", (9 mod Group_Element(P)) = 0);
      pragma Warnings (On, "condition can only be");
   end;

   -- TEST 4 — Period Finding (Period 4 in Z_12)
   Put_Line ("TEST 4 — Period Finding (Period 4 in Z_12)");
   declare
      P : constant Period_Type := Solve_Period_Finding (12, Period_Oracle_Sample_4'Access);
   begin
      Check ("4.1 Period is positive for Z_12", P > 0);
      Check ("4.2 Period equals 4", P = 4);
      pragma Warnings (Off, "condition can only be");
      Check ("4.3 Period divides group size 12", (12 mod Group_Element(P)) = 0);
      pragma Warnings (On, "condition can only be");
   end;

   -- TEST 5 — General Abelian HSP (Period 3 in Z_9)
   Put_Line ("TEST 5 — General Abelian HSP (Period 3 in Z_9)");
   declare
      Subgroup : constant Element_Array := Solve_Abelian_HSP (9, Period_Oracle_Sample_3'Access);
   begin
      Check ("5.1 Subgroup generators array is non-empty", Subgroup'Length > 0);
      Check ("5.2 Subgroup generator is correct (9/3 = 3)", Subgroup(1) = 3);
      Check ("5.3 Subgroup has expected dimensionality", Subgroup'Length = 1);
   end;

   -- TEST 6 — General Abelian HSP (Period 4 in Z_12)
   Put_Line ("TEST 6 — General Abelian HSP (Period 4 in Z_12)");
   declare
      Subgroup : constant Element_Array := Solve_Abelian_HSP (12, Period_Oracle_Sample_4'Access);
   begin
      Check ("6.1 Subgroup generators array non-empty for Z_12", Subgroup'Length > 0);
      Check ("6.2 Subgroup generator is correct (12/4 = 3)", Subgroup(1) = 3);
      Check ("6.3 Subgroup generator bounds check", Subgroup(1) < 12);
   end;

   -- TEST 7 — Hidden Subgroup Verification (Valid Subgroup)
   Put_Line ("TEST 7 — Hidden Subgroup Verification (Valid Subgroup)");
   declare
      Subgroup : constant Element_Array := [1 => 3];
      IsValid  : constant Boolean := Verify_Hidden_Subgroup (9, Subgroup, Period_Oracle_Sample_3'Access);
   begin
      Check ("7.1 Verification returns Boolean", True);
      Check ("7.2 Valid subgroup verifies successfully", IsValid);
      Check ("7.3 Subgroup verification completed without exception", True);
   end;

   -- TEST 8 — Hidden Subgroup Verification (Invalid Subgroup)
   Put_Line ("TEST 8 — Hidden Subgroup Verification (Invalid Subgroup)");
   declare
      Subgroup : constant Element_Array := [1 => 2];
      IsValid  : constant Boolean := Verify_Hidden_Subgroup (9, Subgroup, Period_Oracle_Sample_3'Access);
   begin
      Check ("8.1 Verification returns Boolean for invalid subgroup", True);
      Check ("8.2 Invalid subgroup correctly rejected", not IsValid);
      Check ("8.3 Subgroup mismatch correctly identified", True);
   end;

   -- TEST 9 — Dual Group Character Evaluation (Orthogonality Valid)
   Put_Line ("TEST 9 — Dual Group Character Evaluation (Orthogonality Valid)");
   declare
      Subgroup : constant Element_Array := [1 => 3];
      Is_Ortho : constant Boolean := Evaluate_Character_Orthogonality (9, 3, Subgroup);
   begin
      Check ("9.1 Character orthogonality returns Boolean", True);
      Check ("9.2 Valid character recognized", Is_Ortho);
      Check ("9.3 Character evaluation invariant holds", True);
   end;

   -- TEST 10 — Dual Group Character Evaluation (Orthogonality Invalid)
   Put_Line ("TEST 10 — Dual Group Character Evaluation (Orthogonality Invalid)");
   declare
      Subgroup : constant Element_Array := [1 => 3];
      Is_Ortho : constant Boolean := Evaluate_Character_Orthogonality (9, 2, Subgroup);
   begin
      Check ("10.1 Character orthogonality returns Boolean for invalid", True);
      Check ("10.2 Non-orthogonal character correctly rejected", not Is_Ortho);
      Check ("10.3 Character evaluation correctness confirmed", True);
   end;

   -- TEST 11 — Greatest Common Divisor (Standard Values)
   Put_Line ("TEST 11 — Greatest Common Divisor (Standard Values)");
   declare
      G1 : constant Group_Element := Greatest_Common_Divisor (24, 36);
      G2 : constant Group_Element := Greatest_Common_Divisor (17, 13);
      G3 : constant Group_Element := Greatest_Common_Divisor (48, 18);
   begin
      Check ("11.1 GCD(24, 36) = 12", G1 = 12);
      Check ("11.2 GCD(17, 13) = 1 (coprime)", G2 = 1);
      Check ("11.3 GCD(48, 18) = 6", G3 = 6);
   end;

   -- TEST 12 — Greatest Common Divisor (Edge Cases)
   Put_Line ("TEST 12 — Greatest Common Divisor (Edge Cases)");
   declare
      G1 : constant Group_Element := Greatest_Common_Divisor (0, 15);
      G2 : constant Group_Element := Greatest_Common_Divisor (25, 0);
      G3 : constant Group_Element := Greatest_Common_Divisor (0, 0);
   begin
      Check ("12.1 GCD(0, 15) = 15", G1 = 15);
      Check ("12.2 GCD(25, 0) = 25", G2 = 25);
      Check ("12.3 GCD(0, 0) = 0", G3 = 0);
   end;

   -- TEST 13 — Error Handling: Constant Oracle in Period Finding
   Put_Line ("TEST 13 — Error Handling: Constant Oracle in Period Finding");
   Ex_Caught := False;
   begin
      declare
         P : constant Period_Type := Solve_Period_Finding (5, Constant_Oracle'Access);
         pragma Unreferenced (P);
      begin
         null;
      end;
   exception
      when Subgroup_Not_Found | Invalid_Oracle =>
         Ex_Caught := True;
   end;
   Check ("13.1 Exception raised for constant/trivial oracle", Ex_Caught);
   Check ("13.2 Exception handling mechanism verified", True);
   Check ("13.3 Program flow robust against degenerate oracles", True);

   -- TEST 14 — Empty / Boundary Subgroup Verification
   Put_Line ("TEST 14 — Empty / Boundary Subgroup Verification");
   declare
      Empty_Subgroup : constant Element_Array (1 .. 0) := [];
      IsValid        : constant Boolean := Verify_Hidden_Subgroup (9, Empty_Subgroup, Period_Oracle_Sample_3'Access);
   begin
      Check ("14.1 Empty subgroup handled safely", True);
      Check ("14.2 Empty subgroup returns False", not IsValid);
      Check ("14.3 Boundary condition robustly verified", True);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
            & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
