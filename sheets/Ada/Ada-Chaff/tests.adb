--  Standalone test suite for Chaff (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with Chaff; use Chaff;

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
   Check (Slot_Of (1) = 1, "Slot_Of(+1)=1");
   Check (Slot_Of (-1) = 2, "Slot_Of(-1)=2");
   Check (Slot_Of (2) = 3, "Slot_Of(+2)=3");
   Check (Slot_Of (-2) = 4, "Slot_Of(-2)=4");
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
      Set_Num_Vars (F, 3);
      Check (F.Num_Vars = 3, "Set_Num_Vars=3");
      Raised := False;
      begin
         Add_Clause_From_Literals (F, [1, 1, others => 0], 2);
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "duplicate literal rejected");
      Raised := False;
      begin
         Add_Clause_From_Literals (F, [0, 2, others => 0], 2);
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "zero literal rejected");
   end;

   ---------------------------------------------------------------------
   Section ("3. Watch invariants (Init_Watches)");
   ---------------------------------------------------------------------
   declare
      F  : Formula;
      S  : Solver_State;
      Wp : Watch_Pair;
   begin
      Build_Two_Clause_Sat (F);
      Init_Watches (F, S);
      Check (S.Initialized, "Initialized flag");
      Check (Watches_Invariant (F, S), "Watches_Invariant two-clause");
      Wp := Get_Watch_Pair (S, 1);
      Check (Wp.W1 = 1 and then Wp.W2 = 2, "clause1 watches 1,2");
      Wp := Get_Watch_Pair (S, 2);
      Check (Wp.W1 = 1 and then Wp.W2 = 2, "clause2 watches 1,2");

      Build_Chain_Units (F);
      Init_Watches (F, S);
      Check (Watches_Invariant (F, S), "Watches_Invariant chain");
      Wp := Get_Watch_Pair (S, 1);
      Check (Wp.W1 = 1 and then Wp.W2 = 1, "unit clause self-watch");
      Wp := Get_Watch_Pair (S, 2);
      Check (Wp.W1 /= Wp.W2, "binary watches distinct");

      Build_Empty_Clause (F);
      Init_Watches (F, S);
      Wp := Get_Watch_Pair (S, 1);
      Check (Wp.W1 = 0 and then Wp.W2 = 0, "empty clause no watches");
      Check (Watches_Invariant (F, S), "Watches_Invariant empty clause");

      Build_Small_3SAT_Sat (F);
      Init_Watches (F, S);
      Check (Watches_Invariant (F, S), "Watches_Invariant 3SAT sat");
   end;

   ---------------------------------------------------------------------
   Section ("4. Unit propagation via watches (Propagate)");
   ---------------------------------------------------------------------
   declare
      F    : Formula;
      S    : Solver_State;
      A    : Assignment := [others => Unassigned];
      Conf : Boolean := False;
   begin
      Build_Chain_Units (F);
      Init_Watches (F, S);
      Enqueue (A, S, 1, Conf);
      Check (not Conf, "enqueue +a ok");
      Propagate (F, A, S, Conf);
      Check (not Conf, "propagate chain no conflict");
      Check (A (1) = Is_True, "chain forces a=T");
      Check (A (2) = Is_True, "chain forces b=T");
      Check (A (3) = Is_True, "chain forces c=T");
      Check (Watches_Invariant (F, S), "watches ok after BCP");
   end;

   declare
      F    : Formula;
      S    : Solver_State;
      A    : Assignment := [others => Unassigned];
      Conf : Boolean := False;
   begin
      Build_Contradictory_Units (F);
      Init_Watches (F, S);
      Enqueue (A, S, 1, Conf);
      Check (not Conf, "enqueue +a");
      Enqueue (A, S, -1, Conf);
      Check (Conf, "enqueue -a conflicts");
   end;

   declare
      F    : Formula;
      S    : Solver_State;
      A    : Assignment := [others => Unassigned];
      Conf : Boolean := False;
   begin
      Build_Two_Clause_Sat (F);
      Init_Watches (F, S);
      Enqueue (A, S, -2, Conf);  --  b=False
      Propagate (F, A, S, Conf);
      --  (a∨b) with b false → a; (¬a∨b) with b false → ¬a; conflict
      Check (Conf, "b=F yields conflict on two-clause");
   end;

   declare
      F    : Formula;
      S    : Solver_State;
      A    : Assignment := [others => Unassigned];
      Conf : Boolean := False;
      Ok   : Boolean;
   begin
      Build_Two_Clause_Sat (F);
      Init_Watches (F, S);
      Enqueue (A, S, 1, Conf);  -- a=True
      Propagate (F, A, S, Conf);
      Check (not Conf, "a=T no conflict");
      --  second clause (¬a∨b) becomes unit b
      Check (A (2) = Is_True, "a=T forces b via watch");
      Assign_Literal (A, 2, Ok);
      Check (Ok, "Assign_Literal idempotent on b");
   end;

   ---------------------------------------------------------------------
   Section ("5. VSIDS bump / decay / Choose_VSIDS");
   ---------------------------------------------------------------------
   declare
      F : Formula;
      S : Solver_State;
      A : constant Assignment := [others => Unassigned];
      V : Variable_Count;
   begin
      Build_Small_3SAT_Sat (F);
      Init_Watches (F, S);
      Check (Get_Activity (S, 1) = 0.0, "activity starts 0");
      Check (Get_Activity (S, 2) = 0.0, "activity2 starts 0");
      Bump_Activity (S, 2);
      Bump_Activity (S, 2);
      Bump_Activity (S, 1);
      Check (Get_Activity (S, 2) > Get_Activity (S, 1), "var2 > var1 after bumps");
      V := Choose_VSIDS (F, A, S);
      Check (V = 2, "Choose_VSIDS picks highest (2)");
      --  Tie-break low index
      Init_Watches (F, S);
      Bump_Activity (S, 1);
      Bump_Activity (S, 3);
      --  equal bumps: both 1.0; pick lowest index among those with max
      --  but need equal activity — bump 3 once more then decay? 
      --  After one bump each, both 1.0; Choose should pick 1 (lower index)
      --  Wait we bumped 1 and 3 once each — max is 1.0 for both; lowest is 1
      V := Choose_VSIDS (F, A, S);
      Check (V = 1, "tie-break lowest index");

      declare
         Before : constant Float := Get_Activity (S, 1);
      begin
         Decay_Activities (S);
         Check (Get_Activity (S, 1) < Before, "Decay reduces activity");
         Check (abs (Get_Activity (S, 1) - Before * Decay_Factor) < 1.0e-5,
                "Decay multiplies by Decay_Factor");
      end;

      Bump_Clause_Activities (F, S, 1);
      Check (Get_Activity (S, 1) > 0.0, "Bump_Clause_Activities touches vars");
      Check (Choose_Variable (F, A, S) = Choose_VSIDS (F, A, S),
             "Choose_Variable aliases VSIDS");
   end;

   ---------------------------------------------------------------------
   Section ("6. Solve / Is_Satisfiable toys");
   ---------------------------------------------------------------------
   declare
      F : Formula;
      R : Solve_Result;
   begin
      Build_Empty_Formula (F);
      R := Solve (F);
      Check (R.Status = Satisfiable, "empty formula SAT");
      Check (Is_Satisfiable (F), "Is_Satisfiable empty");

      Build_Empty_Clause (F);
      R := Solve (F);
      Check (R.Status = Unsatisfiable, "empty clause UNSAT");
      Check (not Is_Satisfiable (F), "not Is_Satisfiable empty clause");

      Build_Contradictory_Units (F);
      R := Solve (F);
      Check (R.Status = Unsatisfiable, "units contradict UNSAT");

      Build_Two_Clause_Sat (F);
      R := Solve (F);
      Check (R.Status = Satisfiable, "two-clause SAT");
      Check (Model_Satisfies (F, R.Result_Model), "model satisfies two-clause");
      Check (R.Result_Model.Values (2) = Is_True, "model has b=True");

      Build_Chain_Units (F);
      R := Solve (F);
      Check (R.Status = Satisfiable, "chain SAT");
      Check (Model_Satisfies (F, R.Result_Model), "model satisfies chain");
      Check (R.Result_Model.Values (1) = Is_True, "chain model a");
      Check (R.Result_Model.Values (2) = Is_True, "chain model b");
      Check (R.Result_Model.Values (3) = Is_True, "chain model c");

      Build_Small_3SAT_Sat (F);
      R := Solve (F);
      Check (R.Status = Satisfiable, "3SAT toy SAT");
      Check (Model_Satisfies (F, R.Result_Model), "3SAT model ok");

      Build_Small_3SAT_Unsat (F);
      R := Solve (F);
      Check (R.Status = Unsatisfiable, "3SAT toy UNSAT");
      Check (not Is_Satisfiable (F), "not sat unsat toy");
   end;

   ---------------------------------------------------------------------
   Section ("7. DIMACS lite + clause queries");
   ---------------------------------------------------------------------
   declare
      F : Formula;
      R : Solve_Result;
      A : Assignment := [others => Unassigned];
      C : Clause;
   begin
      From_DIMACS_Lite (F, "c comment" & ASCII.LF &
                        "p cnf 2 2" & ASCII.LF &
                        "1 2 0" & ASCII.LF &
                        "-1 2 0" & ASCII.LF);
      Check (F.Num_Vars = 2 and then F.Num_Clauses = 2, "DIMACS parse counts");
      R := Solve (F);
      Check (R.Status = Satisfiable, "DIMACS two-clause SAT");
      Check (Model_Satisfies (F, R.Result_Model), "DIMACS model");

      C := (Length => 2, Lits => [1, -2, others => 0]);
      Check (not Clause_Is_Empty (C), "not empty");
      Check (not Clause_Is_Satisfied (C, A), "unassigned not sat");
      Check (not Clause_Is_Conflict (C, A), "unassigned not conflict");
      Check (Unit_Literal (C, A) = 0, "not unit yet");
      A (2) := Is_True;  --  -2 false
      Check (Unit_Literal (C, A) = 1, "unit +1");
      A (1) := Is_True;
      Check (Clause_Is_Satisfied (C, A), "satisfied");
      Check (not Has_Empty_Clause (F), "no empty in F");
      Check (not Formula_Has_Conflict (F, A), "no conflict with a=T b=T");
   end;

   ---------------------------------------------------------------------
   Section ("8. More sat/unsat + Not_Initialized");
   ---------------------------------------------------------------------
   declare
      F : Formula;
      S : Solver_State;
      A : Assignment := [others => Unassigned];
      Conf : Boolean := False;
      Raised : Boolean := False;
      R : Solve_Result;
   begin
      begin
         Enqueue (A, S, 1, Conf);
      exception
         when Not_Initialized =>
            Raised := True;
      end;
      Check (Raised, "Enqueue before Init raises");

      Raised := False;
      begin
         Propagate (F, A, S, Conf);
      exception
         when Not_Initialized =>
            Raised := True;
      end;
      Check (Raised, "Propagate before Init raises");

      --  (x) alone
      Clear (F);
      Set_Num_Vars (F, 1);
      Add_Clause_From_Literals (F, [1, others => 0], 1);
      R := Solve (F);
      Check (R.Status = Satisfiable, "single unit SAT");
      Check (R.Result_Model.Values (1) = Is_True, "single unit model");

      --  Horn-ish
      Clear (F);
      Set_Num_Vars (F, 4);
      Add_Clause_From_Literals (F, [-1, 2, others => 0], 2);
      Add_Clause_From_Literals (F, [-2, 3, others => 0], 2);
      Add_Clause_From_Literals (F, [-3, 4, others => 0], 2);
      Add_Clause_From_Literals (F, [1, others => 0], 1);
      R := Solve (F);
      Check (R.Status = Satisfiable, "horn chain SAT");
      Check (Model_Satisfies (F, R.Result_Model), "horn model");

      --  pigeon 2 into 1 style unsat
      Clear (F);
      Set_Num_Vars (F, 2);
      Add_Clause_From_Literals (F, [1, 2, others => 0], 2);
      Add_Clause_From_Literals (F, [-1, others => 0], 1);
      Add_Clause_From_Literals (F, [-2, others => 0], 1);
      R := Solve (F);
      Check (R.Status = Unsatisfiable, "forced both false vs or UNSAT");
   end;

   ---------------------------------------------------------------------
   Section ("9. Watch re-assignment / All_Clauses");
   ---------------------------------------------------------------------
   declare
      F    : Formula;
      S    : Solver_State;
      A    : Assignment := [others => Unassigned];
      Conf : Boolean := False;
      R    : Solve_Result;
   begin
      Clear (F);
      Set_Num_Vars (F, 3);
      --  (a ∨ b ∨ c); assign ¬a then ¬b → unit c
      Add_Clause_From_Literals (F, [1, 2, 3, others => 0], 3);
      Init_Watches (F, S);
      Check (Watches_Invariant (F, S), "ternary watches init");
      Enqueue (A, S, -1, Conf);
      Propagate (F, A, S, Conf);
      Check (not Conf, "¬a ok");
      Enqueue (A, S, -2, Conf);
      Propagate (F, A, S, Conf);
      Check (not Conf, "¬b ok");
      Check (A (3) = Is_True, "ternary forces c");
      Check (All_Clauses_Satisfied (F, A), "clause satisfied");
      Check (Watches_Invariant (F, S), "watches after rewatch");

      R := Solve (F);
      Check (R.Status = Satisfiable, "ternary alone SAT");
   end;

   ---------------------------------------------------------------------
   Section ("10. Capacity / Parse_Error smoke");
   ---------------------------------------------------------------------
   declare
      F : Formula;
      Raised : Boolean;
   begin
      Raised := False;
      begin
         From_DIMACS_Lite (F, "p cnf 2 1" & ASCII.LF & "1 x 0" & ASCII.LF);
      exception
         when Parse_Error =>
            Raised := True;
         when others =>
            Raised := True;
      end;
      Check (Raised, "bad DIMACS raises");

      Clear (F);
      Set_Num_Vars (F, 1);
      Raised := False;
      begin
         for K in 1 .. Max_Clauses + 1 loop
            Add_Clause_From_Literals (F, [1, others => 0], 1);
         end loop;
      exception
         when Capacity_Exceeded =>
            Raised := True;
      end;
      Check (Raised, "Capacity_Exceeded on too many clauses");
   end;

   ---------------------------------------------------------------------
   Section ("11. Extra VSIDS ordering + sat batch");
   ---------------------------------------------------------------------
   declare
      F : Formula;
      S : Solver_State;
      A : Assignment := [others => Unassigned];
      V : Variable_Count;
      R : Solve_Result;
   begin
      Build_Small_3SAT_Sat (F);
      Init_Watches (F, S);
      for K in 1 .. 5 loop
         Bump_Activity (S, 3);
      end loop;
      Bump_Activity (S, 1);
      V := Choose_VSIDS (F, A, S);
      Check (V = 3, "heavy bumps prefer var 3");
      A (3) := Is_True;
      V := Choose_VSIDS (F, A, S);
      Check (V = 1, "after assign 3, pick 1 over 2");

      Clear (F);
      Set_Num_Vars (F, 3);
      Add_Clause_From_Literals (F, [1, -2, others => 0], 2);
      Add_Clause_From_Literals (F, [2, -3, others => 0], 2);
      Add_Clause_From_Literals (F, [3, -1, others => 0], 2);
      R := Solve (F);
      Check (R.Status = Satisfiable, "cycle implications SAT");
      Check (Model_Satisfies (F, R.Result_Model), "cycle model");

      Clear (F);
      Set_Num_Vars (F, 3);
      Add_Clause_From_Literals (F, [1, others => 0], 1);
      Add_Clause_From_Literals (F, [-1, others => 0], 1);
      Add_Clause_From_Literals (F, [2, 3, others => 0], 2);
      R := Solve (F);
      Check (R.Status = Unsatisfiable, "units + extra still UNSAT");

      declare
         S2 : Solver_State;
         A2 : Assignment := [others => Unassigned];
         Conf2 : Boolean := False;
         Act : Float;
      begin
         Init_Watches (F, S2);
         Enqueue (A2, S2, 1, Conf2);
         Propagate (F, A2, S2, Conf2);
         Check (Conf2, "units formula conflicts under +a alone");
         Check (Get_Activity (S2, 1) >= 0.0, "activity non-negative");
         Bump_Activity (S2, 2);
         Act := Get_Activity (S2, 2);
         Check (Act > 0.0, "bump raises activity of var 2");
         Decay_Activities (S2);
         Check (Get_Activity (S2, 2) < Act, "manual decay after bump");
         Check (Watches_Invariant (F, S2), "invariant after conflict BCP");
      end;
   end;

   New_Line;
   Put_Line ("========================================");
   Put_Line ("Pass_Count =" & Pass_Count'Image);
   Put_Line ("Fail_Count =" & Fail_Count'Image);
   if Fail_Count = 0 and then Pass_Count >= 80 then
      Put_Line ("ALL PASSED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Put_Line ("FAILED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
