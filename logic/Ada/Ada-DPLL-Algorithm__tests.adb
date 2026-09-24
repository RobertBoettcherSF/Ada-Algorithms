with Ada.Text_IO; use Ada.Text_IO;
with DPLL;        use DPLL;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS - " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL - " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   --  Helper to create a single-literal clause
   function C1 (L1 : Literal) return Clause is
      Result : Clause (Length => 1);
   begin
      Result.Lits (1) := L1;
      return Result;
   end C1;

   --  Helper to create a two-literal clause
   function C2 (L1, L2 : Literal) return Clause is
      Result : Clause (Length => 2);
   begin
      Result.Lits (1) := L1;
      Result.Lits (2) := L2;
      return Result;
   end C2;

   --  Helper to create a three-literal clause
   function C3 (L1, L2, L3 : Literal) return Clause is
      Result : Clause (Length => 3);
   begin
      Result.Lits (1) := L1;
      Result.Lits (2) := L2;
      Result.Lits (3) := L3;
      return Result;
   end C3;

begin
   ----------------------------------------------------------------------------
   -- TEST 1 - Literal Manipulation and Negation
   ----------------------------------------------------------------------------
   Put_Line ("TEST 1 - Literal Manipulation and Invariants");
   declare
      L_Pos : constant Literal := Make_Pos (3);
      L_Neg : constant Literal := Make_Neg (3);
   begin
      Check ("1.1 Make_Pos produces positive sign", L_Pos.Sign = Positive_Sign and L_Pos.Var = 3);
      Check ("1.2 Make_Neg produces negative sign", L_Neg.Sign = Negative_Sign and L_Neg.Var = 3);
      Check ("1.3 Double negation identity",
             Negate (Negate (L_Pos)) = L_Pos and Negate (Negate (L_Neg)) = L_Neg);
   end;

   ----------------------------------------------------------------------------
   -- TEST 2 - Empty Formula and Null Cases
   ----------------------------------------------------------------------------
   Put_Line ("TEST 2 - Empty Formula (Trivially Satisfiable)");
   declare
      Empty_F : constant Formula := Formula'(
         Num_Clauses => 0,
         Num_Vars    => 2,
         Clauses     => [others => Clause'(Length => 0, Lits => [others => Make_Pos (1)])]);
      Res     : constant Solver_Result := Solve_DPLL (Empty_F);
   begin
      Check ("2.1 Empty formula is valid", Is_Valid_Formula (Empty_F));
      Check ("2.2 Status is Satisfiable", Res.Status = Satisfiable);
      Check ("2.3 Model verification on empty formula", Is_Model (Empty_F, Res.Model));
   end;

   ----------------------------------------------------------------------------
   -- TEST 3 - Single Literal Satisfiability
   ----------------------------------------------------------------------------
   Put_Line ("TEST 3 - Single Unit Clause (Satisfiable)");
   declare
      F : Formula (Num_Clauses => 1, Num_Vars => 1);
   begin
      F.Clauses (1) := C1 (Make_Pos (1));
      declare
         Res : constant Solver_Result := Solve_DPLL (F);
      begin
         Check ("3.1 Single unit clause is valid", Is_Valid_Formula (F));
         Check ("3.2 Status is Satisfiable", Res.Status = Satisfiable);
         Check ("3.3 Assigned model sets Var 1 to True", Res.Model (1) = Assigned_True);
      end;
   end;

   ----------------------------------------------------------------------------
   -- TEST 4 - Direct Unit Contradiction (P and not P)
   ----------------------------------------------------------------------------
   Put_Line ("TEST 4 - Immediate Contradiction (Unsatisfiable)");
   declare
      F : Formula (Num_Clauses => 2, Num_Vars => 1);
   begin
      F.Clauses (1) := C1 (Make_Pos (1));
      F.Clauses (2) := C1 (Make_Neg (1));
      declare
         Res : constant Solver_Result := Solve_DPLL (F);
      begin
         Check ("4.1 Formula is valid", Is_Valid_Formula (F));
         Check ("4.2 Contradiction status is Unsatisfiable", Res.Status = Unsatisfiable);
         Check ("4.3 Unit propagation alone detects contradiction",
                Unit_Propagation_Only (F).Status = Unsatisfiable);
      end;
   end;

   ----------------------------------------------------------------------------
   -- TEST 5 - Unit Propagation Chain (Horn-like resolution)
   ----------------------------------------------------------------------------
   Put_Line ("TEST 5 - Cascading Unit Propagation");
   declare
      F : Formula (Num_Clauses => 3, Num_Vars => 3);
   begin
      F.Clauses (1) := C1 (Make_Pos (1));
      F.Clauses (2) := C2 (Make_Neg (1), Make_Pos (2));
      F.Clauses (3) := C2 (Make_Neg (2), Make_Pos (3));
      declare
         Res_UP   : constant Solver_Result := Unit_Propagation_Only (F);
         Res_DPLL : constant Solver_Result := Solve_DPLL (F);
      begin
         Check ("5.1 Resolved via Unit Propagation Only", Res_UP.Status = Satisfiable);
         Check ("5.2 DPLL also returns Satisfiable", Res_DPLL.Status = Satisfiable);
         Check ("5.3 Correct model deduction (A=T, B=T, C=T)",
                Res_DPLL.Model (1) = Assigned_True and then
                Res_DPLL.Model (2) = Assigned_True and then
                Res_DPLL.Model (3) = Assigned_True);
      end;
   end;

   ----------------------------------------------------------------------------
   -- TEST 6 - Pure Literal Elimination Only
   ----------------------------------------------------------------------------
   Put_Line ("TEST 6 - Pure Literal Elimination");
   declare
      F : Formula (Num_Clauses => 2, Num_Vars => 2);
   begin
      F.Clauses (1) := C2 (Make_Pos (1), Make_Pos (2));
      F.Clauses (2) := C2 (Make_Pos (1), Make_Neg (2));
      declare
         Res_Pure : constant Solver_Result := Pure_Literal_Only (F);
         Res_DPLL : constant Solver_Result := Solve_DPLL (F);
      begin
         Check ("6.1 Pure literal resolves formula", Res_Pure.Status = Satisfiable);
         Check ("6.2 Pure literal assigned True for A", Res_Pure.Model (1) = Assigned_True);
         Check ("6.3 DPLL verifies model", Is_Model (F, Res_DPLL.Model));
      end;
   end;

   ----------------------------------------------------------------------------
   -- TEST 7 - Branching Without Pure Literal Elimination
   ----------------------------------------------------------------------------
   Put_Line ("TEST 7 - Variant Without Pure Literal Elimination");
   declare
      F : Formula (Num_Clauses => 3, Num_Vars => 2);
   begin
      F.Clauses (1) := C2 (Make_Pos (1), Make_Pos (2));
      F.Clauses (2) := C2 (Make_Neg (1), Make_Pos (2));
      F.Clauses (3) := C2 (Make_Pos (1), Make_Neg (2));
      declare
         Res : constant Solver_Result := Solve_Without_Pure_Literal (F);
      begin
         Check ("7.1 Formula is Satisfiable", Res.Status = Satisfiable);
         Check ("7.2 Model verified", Is_Model (F, Res.Model));
         Check ("7.3 Both A and B are True in unique solution",
                Res.Model (1) = Assigned_True and Res.Model (2) = Assigned_True);
      end;
   end;

   ----------------------------------------------------------------------------
   -- TEST 8 - 2-SAT Unsatisfiable Cycle
   ----------------------------------------------------------------------------
   Put_Line ("TEST 8 - All Four 2-Variable Combinations (Unsatisfiable)");
   declare
      F : Formula (Num_Clauses => 4, Num_Vars => 2);
   begin
      F.Clauses (1) := C2 (Make_Pos (1), Make_Pos (2));
      F.Clauses (2) := C2 (Make_Pos (1), Make_Neg (2));
      F.Clauses (3) := C2 (Make_Neg (1), Make_Pos (2));
      F.Clauses (4) := C2 (Make_Neg (1), Make_Neg (2));
      declare
         Res_Default : constant Solver_Result := Solve_DPLL (F, First_Unassigned);
         Res_MOMS    : constant Solver_Result := Solve_DPLL (F, MOMS);
         Res_NoPure  : constant Solver_Result := Solve_Without_Pure_Literal (F);
      begin
         Check ("8.1 Default heuristic detects unsat", Res_Default.Status = Unsatisfiable);
         Check ("8.2 MOMS heuristic detects unsat", Res_MOMS.Status = Unsatisfiable);
         Check ("8.3 No-pure variant detects unsat", Res_NoPure.Status = Unsatisfiable);
      end;
   end;

   ----------------------------------------------------------------------------
   -- TEST 9 - Branching Heuristic: Max Occurrences
   ----------------------------------------------------------------------------
   Put_Line ("TEST 9 - Branching Heuristic: Max Occurrences");
   declare
      F : Formula (Num_Clauses => 3, Num_Vars => 3);
   begin
      F.Clauses (1) := C2 (Make_Pos (3), Make_Pos (1));
      F.Clauses (2) := C2 (Make_Pos (3), Make_Neg (2));
      F.Clauses (3) := C2 (Make_Pos (2), Make_Neg (1));
      declare
         Res : constant Solver_Result := Solve_DPLL (F, Max_Occurrences);
      begin
         Check ("9.1 Solver returns Satisfiable", Res.Status = Satisfiable);
         Check ("9.2 Model is verified", Is_Model (F, Res.Model));
         Check ("9.3 Formula remains valid under heuristic", Is_Valid_Formula (F));
      end;
   end;

   ----------------------------------------------------------------------------
   -- TEST 10 - Branching Heuristic: MOMS Heuristic
   ----------------------------------------------------------------------------
   Put_Line ("TEST 10 - Branching Heuristic: MOMS");
   declare
      F : Formula (Num_Clauses => 3, Num_Vars => 3);
   begin
      F.Clauses (1) := C3 (Make_Pos (1), Make_Pos (2), Make_Pos (3));
      F.Clauses (2) := C2 (Make_Pos (2), Make_Neg (1));
      F.Clauses (3) := C2 (Make_Neg (2), Make_Pos (3));
      declare
         Res : constant Solver_Result := Solve_DPLL (F, MOMS);
      begin
         Check ("10.1 Solved via MOMS", Res.Status = Satisfiable);
         Check ("10.2 Resulting model satisfies formula", Is_Model (F, Res.Model));
         Check ("10.3 Solution model assigns valid states",
                Res.Model (1) /= Unassigned and Res.Model (2) /= Unassigned);
      end;
   end;

   ----------------------------------------------------------------------------
   -- TEST 11 - 3-SAT Pigeonhole Principle (PHP 3 into 2: Unsatisfiable)
   ----------------------------------------------------------------------------
   Put_Line ("TEST 11 - Pigeonhole Principle (PHP 3 to 2, UNSAT)");
   declare
      F : Formula (Num_Clauses => 9, Num_Vars => 6);
   begin
      F.Clauses (1) := C2 (Make_Pos (1), Make_Pos (2));
      F.Clauses (2) := C2 (Make_Pos (3), Make_Pos (4));
      F.Clauses (3) := C2 (Make_Pos (5), Make_Pos (6));

      F.Clauses (4) := C2 (Make_Neg (1), Make_Neg (3));
      F.Clauses (5) := C2 (Make_Neg (1), Make_Neg (5));
      F.Clauses (6) := C2 (Make_Neg (3), Make_Neg (5));

      F.Clauses (7) := C2 (Make_Neg (2), Make_Neg (4));
      F.Clauses (8) := C2 (Make_Neg (2), Make_Neg (6));
      F.Clauses (9) := C2 (Make_Neg (4), Make_Neg (6));

      declare
         Res1 : constant Solver_Result := Solve_DPLL (F, First_Unassigned);
         Res2 : constant Solver_Result := Solve_DPLL (F, Max_Occurrences);
         Res3 : constant Solver_Result := Solve_Without_Pure_Literal (F);
      begin
         Check ("11.1 PHP 3 into 2 is Unsatisfiable (DPLL)", Res1.Status = Unsatisfiable);
         Check ("11.2 PHP 3 into 2 is Unsatisfiable (Max_Occurrences)", Res2.Status = Unsatisfiable);
         Check ("11.3 PHP 3 into 2 is Unsatisfiable (Without Pure Literal)", Res3.Status = Unsatisfiable);
      end;
   end;

   ----------------------------------------------------------------------------
   -- TEST 12 - Error Handling: Invalid Formula Detection
   ----------------------------------------------------------------------------
   Put_Line ("TEST 12 - Error Handling & Precondition Validation");
   declare
      Invalid_F : Formula (Num_Clauses => 1, Num_Vars => 2);
      Ex_Caught : Boolean := False;
   begin
      Invalid_F.Clauses (1) := C1 (Make_Pos (4));

      Check ("12.1 Is_Valid_Formula detects out-of-bounds variable", not Is_Valid_Formula (Invalid_F));

      begin
         declare
            Unused_Res : constant Solver_Result := Solve_DPLL (Invalid_F);
            pragma Unreferenced (Unused_Res);
         begin
            null;
         end;
      exception
         when Invalid_Formula_Error =>
            Ex_Caught := True;
      end;
      Check ("12.2 Solve_DPLL raises Invalid_Formula_Error", Ex_Caught);

      Ex_Caught := False;
      begin
         declare
            Unused_Res : constant Solver_Result := Unit_Propagation_Only (Invalid_F);
            pragma Unreferenced (Unused_Res);
         begin
            null;
         end;
      exception
         when Invalid_Formula_Error =>
            Ex_Caught := True;
      end;
      Check ("12.3 Unit_Propagation_Only raises Invalid_Formula_Error", Ex_Caught);
   end;

   ----------------------------------------------------------------------------
   -- TEST 13 - Invariants & Model Evaluation Integrity
   ----------------------------------------------------------------------------
   Put_Line ("TEST 13 - Model Evaluation and Invariant Checking");
   declare
      F : Formula (Num_Clauses => 2, Num_Vars => 2);
      M : Valuation := [others => Unassigned];
   begin
      F.Clauses (1) := C2 (Make_Pos (1), Make_Neg (2));
      F.Clauses (2) := C1 (Make_Pos (2));

      Check ("13.1 Unassigned model does not satisfy formula", not Is_Model (F, M));

      M (1) := Assigned_False;
      M (2) := Assigned_False;
      Check ("13.2 Conflicting model evaluated as false", not Is_Model (F, M));

      M (1) := Assigned_True;
      M (2) := Assigned_True;
      Check ("13.3 Satisfying valuation returns true in Is_Model", Is_Model (F, M));
   end;

   ----------------------------------------------------------------------------
   -- Summary
   ----------------------------------------------------------------------------
   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
