--  Standalone test suite for DPLL (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with DPLL; use DPLL;

procedure Tests
  with SPARK_Mode => Off
is

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

   function Model_Var_Is
     (M : Model; V : Variable_Id; Want : Truth_Value) return Boolean
   is
   begin
      return M.Values (V) = Want;
   end Model_Var_Is;

begin
   ---------------------------------------------------------------------
   Section ("1. Literal helpers");
   ---------------------------------------------------------------------
   Check (Var_Of (3) = 3, "Var_Of(+3)=3");
   Check (Var_Of (-5) = 5, "Var_Of(-5)=5");
   Check (Is_Positive (2), "Is_Positive(+2)");
   Check (not Is_Positive (-2), "not Is_Positive(-2)");
   Check (Negate (4) = -4, "Negate(+4)=-4");
   Check (Negate (-7) = 7, "Negate(-7)=+7");
   Check (Make_Literal (1, True) = 1, "Make_Literal(1,True)=+1");
   Check (Make_Literal (1, False) = -1, "Make_Literal(1,False)=-1");
   declare
      A : Assignment := [others => Unassigned];
   begin
      A (1) := Is_True;
      A (2) := Is_False;
      Check (Lit_Is_True (1, A), "Lit_Is_True(+1) when x1=T");
      Check (Lit_Is_False (-1, A), "Lit_Is_False(-1) when x1=T");
      Check (Lit_Is_True (-2, A), "Lit_Is_True(-2) when x2=F");
      Check (Lit_Is_False (2, A), "Lit_Is_False(+2) when x2=F");
      Check (Lit_Is_Unassigned (3, A), "Lit_Is_Unassigned(3)");
      Check (not Lit_Is_True (3, A), "unassigned not true");
      Check (not Lit_Is_False (3, A), "unassigned not false");
   end;

   ---------------------------------------------------------------------
   Section ("2. Builders / Clear / Add_Clause");
   ---------------------------------------------------------------------
   declare
      F : Formula;
      C : Clause;
      Raised : Boolean;
   begin
      Clear (F);
      Check (F.Num_Vars = 0 and then F.Num_Clauses = 0, "Clear empty");
      C := (Length => 2, Lits => [1, -2, others => 0]);
      Add_Clause (F, C);
      Check (F.Num_Clauses = 1, "Add_Clause count=1");
      Check (F.Num_Vars = 2, "Add_Clause auto Num_Vars=2");
      Check (F.Clauses (1).Lits (1) = 1, "clause lit1");
      Check (F.Clauses (1).Lits (2) = -2, "clause lit2");

      Raised := False;
      begin
         C := (Length => 2, Lits => [1, 1, others => 0]);
         Add_Clause (F, C);
      exception
         when Invalid_Argument => Raised := True;
      end;
      Check (Raised, "duplicate literal → Invalid_Argument");

      Raised := False;
      begin
         C := (Length => 1, Lits => [0, others => 0]);
         Add_Clause (F, C);
      exception
         when Invalid_Argument => Raised := True;
      end;
      Check (Raised, "zero literal → Invalid_Argument");

      Clear (F);
      Set_Num_Vars (F, 3);
      Check (F.Num_Vars = 3, "Set_Num_Vars(3)");
      Add_Clause_From_Literals (F, [1, 2, 3, others => 0], 3);
      Check (F.Num_Clauses = 1 and then F.Clauses (1).Length = 3,
             "Add_Clause_From_Literals");
   end;

   ---------------------------------------------------------------------
   Section ("3. Clause status queries");
   ---------------------------------------------------------------------
   declare
      C : constant Clause := (Length => 2, Lits => [1, -2, others => 0]);
      A : Assignment := [others => Unassigned];
      Empty_C : constant Clause := (Length => 0, Lits => [others => 0]);
   begin
      Check (Clause_Is_Empty (Empty_C), "empty clause");
      Check (not Clause_Is_Empty (C), "non-empty clause");
      Check (not Clause_Is_Satisfied (C, A), "unassigned not sat");
      Check (not Clause_Is_Conflict (C, A), "unassigned not conflict");
      Check (Unit_Literal (C, A) = 0, "two opens → not unit");

      A (1) := Is_False;
      Check (Unit_Literal (C, A) = -2, "unit -2 after x1=F");
      A (2) := Is_False;
      Check (Clause_Is_Satisfied (C, A), "x2=F satisfies -2");
      Check (Unit_Literal (C, A) = 0, "satisfied → not unit");

      A := [others => Unassigned];
      A (1) := Is_False;
      A (2) := Is_True;
      Check (Clause_Is_Conflict (C, A), "both false → conflict");
      Check (Clause_Is_Conflict (Empty_C, A), "empty is conflict");
   end;

   ---------------------------------------------------------------------
   Section ("4. Unit propagation");
   ---------------------------------------------------------------------
   declare
      F : Formula;
      A : Assignment := [others => Unassigned];
      Conflict : Boolean;
      Ok : Boolean;
   begin
      Build_Two_Clause_Sat (F);
      --  Force a=True → unit on second clause gives b=True; first sat.
      Assign_Literal (A, 1, Ok);
      Check (Ok, "assign +1 ok");
      Unit_Propagate (F, A, Conflict);
      Check (not Conflict, "UP no conflict on sat formula");
      Check (A (2) = Is_True, "UP forces b=True");
   end;

   declare
      F : Formula;
      A : Assignment := [others => Unassigned];
      Conflict : Boolean;
   begin
      Build_Contradictory_Units (F);
      Unit_Propagate (F, A, Conflict);
      Check (Conflict, "UP detects (a)∧(¬a)");
   end;

   declare
      F : Formula;
      A : Assignment := [others => Unassigned];
      Conflict : Boolean;
      C : Clause;
   begin
      Clear (F);
      F.Num_Vars := 3;
      --  (x1) ∧ (¬x1 ∨ x2) ∧ (¬x2 ∨ x3) → forces all true
      C := (Length => 1, Lits => [1, others => 0]);
      Add_Clause (F, C);
      C := (Length => 2, Lits => [-1, 2, others => 0]);
      Add_Clause (F, C);
      C := (Length => 2, Lits => [-2, 3, others => 0]);
      Add_Clause (F, C);
      Unit_Propagate (F, A, Conflict);
      Check (not Conflict, "chain UP no conflict");
      Check (A (1) = Is_True, "chain forces x1");
      Check (A (2) = Is_True, "chain forces x2");
      Check (A (3) = Is_True, "chain forces x3");
   end;

   ---------------------------------------------------------------------
   Section ("5. Pure literal elimination");
   ---------------------------------------------------------------------
   declare
      F : Formula;
      A : Assignment := [others => Unassigned];
      Pures : Pure_List;
      Conflict : Boolean;
      C : Clause;
   begin
      Clear (F);
      F.Num_Vars := 2;
      --  (a ∨ b) ∧ (a ∨ ¬b) → a pure positive
      C := (Length => 2, Lits => [1, 2, others => 0]);
      Add_Clause (F, C);
      C := (Length => 2, Lits => [1, -2, others => 0]);
      Add_Clause (F, C);
      Pure_Literals (F, A, Pures);
      Check (Pures.Length = 1, "one pure literal");
      Check (Pures.Lits (1) = 1, "pure is +a");
      Eliminate_Pures (F, A, Conflict);
      Check (not Conflict, "Eliminate_Pures ok");
      Check (A (1) = Is_True, "pure assign a=True");
      Check (All_Clauses_Satisfied (F, A), "pures satisfy formula");
   end;

   declare
      F : Formula;
      A : constant Assignment := [others => Unassigned];
      Pures : Pure_List;
      C : Clause;
   begin
      Clear (F);
      F.Num_Vars := 2;
      C := (Length => 2, Lits => [-1, 2, others => 0]);
      Add_Clause (F, C);
      C := (Length => 1, Lits => [-1, others => 0]);
      Add_Clause (F, C);
      Pure_Literals (F, A, Pures);
      Check (Pures.Length >= 1, "neg pure present");
      declare
         Found_Neg1 : Boolean := False;
      begin
         for I in 1 .. Pures.Length loop
            if Pures.Lits (I) = -1 then
               Found_Neg1 := True;
            end if;
         end loop;
         Check (Found_Neg1, "pure includes -a");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("6. Choose_Variable");
   ---------------------------------------------------------------------
   declare
      F : Formula;
      A : Assignment := [others => Unassigned];
   begin
      Build_Two_Clause_Sat (F);
      Check (Choose_Variable (F, A) = 1, "choose smallest=1");
      A (1) := Is_True;
      Check (Choose_Variable (F, A) = 2
             or else Choose_Variable (F, A) = 0,
             "after x1 assigned choose 2 or 0 if unit would fire");
      --  With x1=T, clause2 unit on +2; clause1 sat. If we don't UP,
      --  choose still sees open lit 2 in clause2? clause1 sat; clause2
      --  has -1 false, +2 open → choose 2.
      Check (Choose_Variable (F, A) = 2, "choose 2 with x1 fixed");
      A (2) := Is_True;
      Check (Choose_Variable (F, A) = 0, "all sat → choose 0");
   end;

   ---------------------------------------------------------------------
   Section ("7. Classic Solve: sat / unsat toys");
   ---------------------------------------------------------------------
   declare
      F : Formula;
      R : Solve_Result;
   begin
      Build_Two_Clause_Sat (F);
      R := Solve (F);
      Check (R.Status = Satisfiable, "(a∨b)∧(¬a∨b) sat");
      Check (Is_Satisfiable (F), "Is_Satisfiable true");
      Check (Model_Satisfies (F, R.Result_Model), "model satisfies two-clause");
      Check (Model_Var_Is (R.Result_Model, 2, Is_True), "model has b=True");

      Build_Contradictory_Units (F);
      R := Solve (F);
      Check (R.Status = Unsatisfiable, "(a)∧(¬a) unsat");
      Check (not Is_Satisfiable (F), "Is_Satisfiable false");

      Build_Empty_Clause (F);
      R := Solve (F);
      Check (R.Status = Unsatisfiable, "empty clause unsat");
      Check (Has_Empty_Clause (F), "Has_Empty_Clause");

      Build_Empty_Formula (F);
      R := Solve (F);
      Check (R.Status = Satisfiable, "empty formula sat");
      Check (Is_Satisfiable (F), "empty Is_Satisfiable");
   end;

   ---------------------------------------------------------------------
   Section ("8. Small 3-SAT toys");
   ---------------------------------------------------------------------
   declare
      F : Formula;
      R : Solve_Result;
   begin
      Build_Small_3SAT_Sat (F);
      R := Solve (F);
      Check (R.Status = Satisfiable, "small 3-SAT sat");
      Check (Model_Satisfies (F, R.Result_Model), "3-SAT model ok");
      Check (F.Num_Vars = 3 and then F.Num_Clauses = 4, "3-SAT shape");

      Build_Small_3SAT_Unsat (F);
      R := Solve (F);
      Check (R.Status = Unsatisfiable, "small unsat (pairwise) unsat");
      Check (not Is_Satisfiable (F), "unsat Is_Satisfiable false");
      Check (F.Num_Clauses = 6, "unsat has 6 binary clauses");
   end;

   ---------------------------------------------------------------------
   Section ("9. Branching / backtrack cases");
   ---------------------------------------------------------------------
   declare
      F : Formula;
      R : Solve_Result;
      C : Clause;
   begin
      --  (x1 ∨ x2) ∧ (¬x1 ∨ x2) ∧ (x1 ∨ ¬x2) — only x1=T,x2=T works? 
      --  Actually (¬x1∨x2)∧(x1∨¬x2)∧(x1∨x2):
      --  From pairwise: forces x1=x2 and at least one true → both true.
      Clear (F);
      F.Num_Vars := 2;
      C := (Length => 2, Lits => [1, 2, others => 0]);
      Add_Clause (F, C);
      C := (Length => 2, Lits => [-1, 2, others => 0]);
      Add_Clause (F, C);
      C := (Length => 2, Lits => [1, -2, others => 0]);
      Add_Clause (F, C);
      R := Solve (F);
      Check (R.Status = Satisfiable, "forced both-true sat");
      Check (Model_Var_Is (R.Result_Model, 1, Is_True), "x1=T");
      Check (Model_Var_Is (R.Result_Model, 2, Is_True), "x2=T");

      --  Add (¬x1 ∨ ¬x2) → unsat
      C := (Length => 2, Lits => [-1, -2, others => 0]);
      Add_Clause (F, C);
      R := Solve (F);
      Check (R.Status = Unsatisfiable, "four binaries unsat");
   end;

   declare
      F : Formula;
      R : Solve_Result;
      C : Clause;
   begin
      --  Single free var: (x1 ∨ ¬x1) tautology via two units? Use (x1∨x2)
      --  only — sat with several models.
      Clear (F);
      F.Num_Vars := 2;
      C := (Length => 2, Lits => [1, 2, others => 0]);
      Add_Clause (F, C);
      R := Solve (F);
      Check (R.Status = Satisfiable, "single clause sat");
      Check (Model_Satisfies (F, R.Result_Model), "single clause model");
   end;

   ---------------------------------------------------------------------
   Section ("10. From_DIMACS_Lite");
   ---------------------------------------------------------------------
   declare
      F : Formula;
      R : Solve_Result;
      Raised : Boolean;
   begin
      From_DIMACS_Lite (F,
        "c comment" & ASCII.LF &
        "p cnf 2 2" & ASCII.LF &
        "1 2 0" & ASCII.LF &
        "-1 2 0" & ASCII.LF);
      Check (F.Num_Vars = 2, "DIMACS vars=2");
      Check (F.Num_Clauses = 2, "DIMACS clauses=2");
      R := Solve (F);
      Check (R.Status = Satisfiable, "DIMACS two-clause sat");
      Check (Model_Satisfies (F, R.Result_Model), "DIMACS model ok");

      From_DIMACS_Lite (F,
        "p cnf 1 2" & ASCII.LF &
        "1 0" & ASCII.LF &
        "-1 0" & ASCII.LF);
      Check (not Is_Satisfiable (F), "DIMACS contradictory units");

      From_DIMACS_Lite (F, "p cnf 0 0" & ASCII.LF);
      Check (Is_Satisfiable (F), "DIMACS empty p cnf 0 0 sat");

      Raised := False;
      begin
         From_DIMACS_Lite (F, "p cnf notanum 1");
      exception
         when Parse_Error => Raised := True;
         when others      => Raised := True;
      end;
      Check (Raised, "bad DIMACS → error");
   end;

   ---------------------------------------------------------------------
   Section ("11. Assign_Literal conflicts");
   ---------------------------------------------------------------------
   declare
      A : Assignment := [others => Unassigned];
      Ok : Boolean;
   begin
      Assign_Literal (A, 1, Ok);
      Check (Ok and then A (1) = Is_True, "first assign +1");
      Assign_Literal (A, 1, Ok);
      Check (Ok, "re-assign same polarity ok");
      Assign_Literal (A, -1, Ok);
      Check (not Ok, "opposite polarity conflict");
      Assign_Literal (A, -2, Ok);
      Check (Ok and then A (2) = Is_False, "assign -2 → Is_False");
   end;

   ---------------------------------------------------------------------
   Section ("12. Formula_Has_Conflict / All_Clauses_Satisfied");
   ---------------------------------------------------------------------
   declare
      F : Formula;
      A : Assignment := [others => Unassigned];
   begin
      Build_Two_Clause_Sat (F);
      Check (not Formula_Has_Conflict (F, A), "no conflict unassigned");
      Check (not All_Clauses_Satisfied (F, A), "not all sat unassigned");
      A (1) := Is_False;
      A (2) := Is_True;
      Check (All_Clauses_Satisfied (F, A), "a=F b=T satisfies");
      Check (not Formula_Has_Conflict (F, A), "no conflict on model");
      A (2) := Is_False;
      Check (Formula_Has_Conflict (F, A), "a=F b=F conflicts clause1");
   end;

   ---------------------------------------------------------------------
   Section ("13. Capacity / Set_Num_Vars guards");
   ---------------------------------------------------------------------
   declare
      F : Formula;
      C : Clause;
      Raised : Boolean;
   begin
      Clear (F);
      Set_Num_Vars (F, 1);
      begin
         C := (Length => 1, Lits => [2, others => 0]);
         --  Add_Clause auto-extends Num_Vars when literals exceed —
         --  document that behaviour: extends to 2.
         Add_Clause (F, C);
      end;
      Check (F.Num_Vars = 2, "Add_Clause extends Num_Vars past Set");

      Clear (F);
      C := (Length => 1, Lits => [1, others => 0]);
      Add_Clause (F, C);
      Raised := False;
      begin
         Set_Num_Vars (F, 0);
      exception
         when Invalid_Argument => Raised := True;
      end;
      Check (Raised, "Set_Num_Vars too small → Invalid_Argument");
   end;

   ---------------------------------------------------------------------
   Section ("14. Unit on single literal clause");
   ---------------------------------------------------------------------
   declare
      F : Formula;
      A : Assignment := [others => Unassigned];
      Conflict : Boolean;
      C : Clause;
   begin
      Clear (F);
      F.Num_Vars := 1;
      C := (Length => 1, Lits => [-1, others => 0]);
      Add_Clause (F, C);
      Check (Unit_Literal (C, A) = -1, "unit clause literal");
      Unit_Propagate (F, A, Conflict);
      Check (not Conflict and then A (1) = Is_False, "UP assigns unit -1");
      Check (All_Clauses_Satisfied (F, A), "unit formula sat after UP");
   end;

   ---------------------------------------------------------------------
   Section ("15. Horn-ish implication chain sat/unsat");
   ---------------------------------------------------------------------
   declare
      F : Formula;
      R : Solve_Result;
      C : Clause;
   begin
      Clear (F);
      F.Num_Vars := 4;
      C := (Length => 1, Lits => [1, others => 0]);
      Add_Clause (F, C);
      C := (Length => 2, Lits => [-1, 2, others => 0]);
      Add_Clause (F, C);
      C := (Length => 2, Lits => [-2, 3, others => 0]);
      Add_Clause (F, C);
      C := (Length => 2, Lits => [-3, 4, others => 0]);
      Add_Clause (F, C);
      R := Solve (F);
      Check (R.Status = Satisfiable, "Horn chain sat");
      Check (Model_Var_Is (R.Result_Model, 4, Is_True), "chain forces x4");

      C := (Length => 1, Lits => [-4, others => 0]);
      Add_Clause (F, C);
      R := Solve (F);
      Check (R.Status = Unsatisfiable, "Horn chain + ¬x4 unsat");
   end;

   ---------------------------------------------------------------------
   Section ("16. Pure + branch mix");
   ---------------------------------------------------------------------
   declare
      F : Formula;
      R : Solve_Result;
      C : Clause;
   begin
      --  (a ∨ b) ∧ (¬b ∨ c) ∧ (¬c ∨ b) — b↔c, a or b
      Clear (F);
      F.Num_Vars := 3;
      C := (Length => 2, Lits => [1, 2, others => 0]);
      Add_Clause (F, C);
      C := (Length => 2, Lits => [-2, 3, others => 0]);
      Add_Clause (F, C);
      C := (Length => 2, Lits => [-3, 2, others => 0]);
      Add_Clause (F, C);
      R := Solve (F);
      Check (R.Status = Satisfiable, "b↔c formula sat");
      Check (Model_Satisfies (F, R.Result_Model), "b↔c model");
      Check (R.Result_Model.Values (2) = R.Result_Model.Values (3), "b equals c");
   end;

   ---------------------------------------------------------------------
   Section ("17. Many independent units");
   ---------------------------------------------------------------------
   declare
      F : Formula;
      R : Solve_Result;
      C : Clause;
   begin
      Clear (F);
      F.Num_Vars := 8;
      for K in 1 .. 8 loop
         if K mod 2 = 1 then
            C := (Length => 1, Lits => [K, others => 0]);
         else
            C := (Length => 1, Lits => [-K, others => 0]);
         end if;
         Add_Clause (F, C);
      end loop;
      R := Solve (F);
      Check (R.Status = Satisfiable, "8 units sat");
      Check (Model_Var_Is (R.Result_Model, 1, Is_True), "x1 true");
      Check (Model_Var_Is (R.Result_Model, 2, Is_False), "x2 false");
      Check (Model_Var_Is (R.Result_Model, 7, Is_True), "x7 true");
      Check (Model_Var_Is (R.Result_Model, 8, Is_False), "x8 false");
   end;

   ---------------------------------------------------------------------
   Section ("18. Tautology-like and already-sat under partial");
   ---------------------------------------------------------------------
   declare
      F : Formula;
      A : Assignment := [others => Unassigned];
      C : Clause;
      R : Solve_Result;
   begin
      --  Unit (+1) with pre-assignment.
      Clear (F);
      F.Num_Vars := 1;
      C := (Length => 1, Lits => [1, others => 0]);
      Add_Clause (F, C);
      A (1) := Is_True;
      Check (All_Clauses_Satisfied (F, A), "pre-assigned sat");
      R := Solve (F);
      Check (R.Status = Satisfiable, "unit +1 solve sat");
      Check (Model_Var_Is (R.Result_Model, 1, Is_True), "model x1=T");
   end;

   ---------------------------------------------------------------------
   Section ("19. Model_Satisfies rejects partial");
   ---------------------------------------------------------------------
   declare
      F : Formula;
      M : Model;
      R : Solve_Result;
   begin
      Build_Two_Clause_Sat (F);
      R := Solve (F);
      M := R.Result_Model;
      Check (Model_Satisfies (F, M), "full model ok");
      M.Values (2) := Unassigned;
      Check (not Model_Satisfies (F, M), "partial model rejected");
      M.Num_Vars := 0;
      Check (not Model_Satisfies (F, M), "Num_Vars too small rejected");
   end;

   ---------------------------------------------------------------------
   Section ("20. DIMACS without p line / multi-lit");
   ---------------------------------------------------------------------
   declare
      F : Formula;
      R : Solve_Result;
   begin
      From_DIMACS_Lite (F,
        "1 -2 3 0" & ASCII.LF &
        "-1 2 0" & ASCII.LF);
      Check (F.Num_Clauses = 2, "no-p DIMACS clauses");
      Check (F.Num_Vars = 3, "no-p DIMACS inferred vars");
      R := Solve (F);
      Check (R.Status = Satisfiable, "no-p DIMACS sat");
      Check (Model_Satisfies (F, R.Result_Model), "no-p model");
   end;

   ---------------------------------------------------------------------
   Section ("21. Backtrack needs both branches");
   ---------------------------------------------------------------------
   declare
      F : Formula;
      R : Solve_Result;
      C : Clause;
   begin
      --  (¬x1 ∨ x2) ∧ (¬x1 ∨ ¬x2) ∧ (x1 ∨ x3) ∧ (x1 ∨ ¬x3)
      --  First two force ¬x1; last two force x1 → unsat.
      Clear (F);
      F.Num_Vars := 3;
      C := (Length => 2, Lits => [-1, 2, others => 0]);
      Add_Clause (F, C);
      C := (Length => 2, Lits => [-1, -2, others => 0]);
      Add_Clause (F, C);
      C := (Length => 2, Lits => [1, 3, others => 0]);
      Add_Clause (F, C);
      C := (Length => 2, Lits => [1, -3, others => 0]);
      Add_Clause (F, C);
      R := Solve (F);
      Check (R.Status = Unsatisfiable, "x1 forced both ways unsat");

      --  Drop last clause → sat with x1=False
      Clear (F);
      F.Num_Vars := 3;
      C := (Length => 2, Lits => [-1, 2, others => 0]);
      Add_Clause (F, C);
      C := (Length => 2, Lits => [-1, -2, others => 0]);
      Add_Clause (F, C);
      C := (Length => 2, Lits => [1, 3, others => 0]);
      Add_Clause (F, C);
      R := Solve (F);
      Check (R.Status = Satisfiable, "drop one → sat");
      Check (Model_Var_Is (R.Result_Model, 1, Is_False), "forces x1=F");
   end;

   ---------------------------------------------------------------------
   Section ("22. Clause_Is_Satisfied edge cases");
   ---------------------------------------------------------------------
   declare
      C : constant Clause := (Length => 3, Lits => [-1, 2, -3, others => 0]);
      A : Assignment := [others => Unassigned];
   begin
      Check (Unit_Literal (C, A) = 0, "3-lit not unit");
      A (1) := Is_True;  --  -1 false
      A (3) := Is_True;  --  -3 false
      Check (Unit_Literal (C, A) = 2, "unit +2");
      A (2) := Is_False;
      Check (Clause_Is_Conflict (C, A), "3-lit all false");
      A (2) := Is_True;
      Check (Clause_Is_Satisfied (C, A), "3-lit sat by +2");
   end;

   New_Line;
   Put_Line ("Pass_Count =" & Pass_Count'Image);
   Put_Line ("Fail_Count =" & Fail_Count'Image);
   if Fail_Count = 0 then
      Put_Line ("ALL PASSED");
   else
      Put_Line ("SOME FAILED");
   end if;

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
