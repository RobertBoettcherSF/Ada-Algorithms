--  Standalone test suite for Davis_Putnam (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with Davis_Putnam; use Davis_Putnam;

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
   declare
      C : constant Clause := (Length => 2, Lits => [1, -2, others => 0]);
   begin
      Check (Clause_Contains (C, 1), "Clause_Contains +1");
      Check (Clause_Contains (C, -2), "Clause_Contains -2");
      Check (not Clause_Contains (C, 2), "not Clause_Contains +2");
      Check (Clause_Mentions_Var (C, 1), "mentions var 1");
      Check (Clause_Mentions_Var (C, 2), "mentions var 2");
      Check (not Clause_Mentions_Var (C, 3), "not mentions var 3");
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
   Section ("3. Empty / unit / pure queries");
   ---------------------------------------------------------------------
   declare
      F : Formula;
      C : Clause;
      Empty_C : constant Clause := (Length => 0, Lits => [others => 0]);
      Pures : Pure_List;
   begin
      Check (Clause_Is_Empty (Empty_C), "empty clause");
      Check (not Clause_Is_Empty ((Length => 1, Lits => [1, others => 0])),
             "non-empty");
      Check (Is_Unit_Clause ((Length => 1, Lits => [-3, others => 0])),
             "unit clause");
      Check (not Is_Unit_Clause ((Length => 2, Lits => [1, 2, others => 0])),
             "binary not unit");

      Build_Contradictory_Units (F);
      Check (Find_Unit_Literal (F) /= 0, "find unit in (a)(¬a)");
      Check (Has_Empty_Clause (F) = False, "no empty yet");

      Clear (F);
      F.Num_Vars := 2;
      C := (Length => 2, Lits => [1, 2, others => 0]);
      Add_Clause (F, C);
      C := (Length => 2, Lits => [1, -2, others => 0]);
      Add_Clause (F, C);
      Check (Find_Pure_Literal (F) = 1, "pure +1 in pure-only formula");
      Collect_Pures (F, Pures);
      Check (Pures.Length = 1 and then Pures.Lits (1) = 1, "Collect_Pures +1");
      Check (Find_Unit_Literal (F) = 0, "no unit in pure-only");
   end;

   ---------------------------------------------------------------------
   Section ("4. Unit_Propagate_Rule");
   ---------------------------------------------------------------------
   declare
      F : Formula;
      Got_Empty : Boolean;
      C : Clause;
   begin
      Build_Contradictory_Units (F);
      Unit_Propagate_Rule (F, Got_Empty);
      Check (Got_Empty, "UP detects (a)∧(¬a) → empty");

      Build_Two_Clause_Sat (F);
      --  Force unit by adding (a): then second clause → (b), first sat.
      C := (Length => 1, Lits => [1, others => 0]);
      Add_Clause (F, C);
      Unit_Propagate_Rule (F, Got_Empty);
      Check (not Got_Empty, "UP on sat extension no empty");
      --  Rebuild and check carefully:
      Clear (F);
      F.Num_Vars := 2;
      C := (Length => 2, Lits => [1, 2, others => 0]);
      Add_Clause (F, C);
      C := (Length => 2, Lits => [-1, 2, others => 0]);
      Add_Clause (F, C);
      C := (Length => 1, Lits => [1, others => 0]);
      Add_Clause (F, C);
      Unit_Propagate_Rule (F, Got_Empty);
      Check (not Got_Empty, "forced-a sat: no empty");
      Check (F.Num_Clauses = 0, "forced-a reduces to empty formula (SAT)");

      --  Chain: (a) (¬a∨b) (¬b∨c) → empty formula
      Clear (F);
      F.Num_Vars := 3;
      C := (Length => 1, Lits => [1, others => 0]);
      Add_Clause (F, C);
      C := (Length => 2, Lits => [-1, 2, others => 0]);
      Add_Clause (F, C);
      C := (Length => 2, Lits => [-2, 3, others => 0]);
      Add_Clause (F, C);
      Unit_Propagate_Rule (F, Got_Empty);
      Check (not Got_Empty, "unit chain no conflict");
      Check (F.Num_Clauses = 0, "unit chain empties formula");
   end;

   ---------------------------------------------------------------------
   Section ("5. Pure_Literal_Rule");
   ---------------------------------------------------------------------
   declare
      F : Formula;
      Changed : Boolean;
   begin
      Build_Pure_Only_Sat (F);
      Check (Find_Pure_Literal (F) = 1, "before pure: +a");
      Pure_Literal_Rule (F, Changed);
      Check (Changed, "pure rule changed");
      Check (F.Num_Clauses = 0, "pure +a deletes both clauses");
      Check (Solve (F) = Satisfiable or else F.Num_Clauses = 0,
             "pure-only residual SAT");
   end;

   ---------------------------------------------------------------------
   Section ("6. Resolve_Clauses / Eliminate_Variable");
   ---------------------------------------------------------------------
   declare
      C1, C2, R : Clause;
      Taut, Ok : Boolean;
      F : Formula;
   begin
      --  (a ∨ b) with (¬a ∨ c) → (b ∨ c)
      C1 := (Length => 2, Lits => [1, 2, others => 0]);
      C2 := (Length => 2, Lits => [-1, 3, others => 0]);
      Resolve_Clauses (C1, C2, 1, R, Taut, Ok);
      Check (Ok and then not Taut, "resolve ok non-taut");
      Check (R.Length = 2, "resolvent length 2");
      Check (Clause_Contains (R, 2) and then Clause_Contains (R, 3),
             "resolvent {b,c}");

      --  (a ∨ b) with (¬a ∨ ¬b) → tautology
      C2 := (Length => 2, Lits => [-1, -2, others => 0]);
      Resolve_Clauses (C1, C2, 1, R, Taut, Ok);
      Check (Ok and then Taut, "resolve tautology b∧¬b");

      --  Eliminate a from (a∨b)(¬a∨b) → (b)
      Build_Two_Clause_Sat (F);
      Check (Count_Pos_Occurrences (F, 1) = 1, "pos a count");
      Check (Count_Neg_Occurrences (F, 1) = 1, "neg a count");
      Eliminate_Variable (F, 1, Ok);
      Check (Ok, "elim a ok");
      Check (F.Num_Clauses = 1, "one resolvent (b)");
      Check (F.Clauses (1).Length = 1 and then F.Clauses (1).Lits (1) = 2,
             "resolvent is (b)");
   end;

   ---------------------------------------------------------------------
   Section ("7. Solve sat / unsat classics");
   ---------------------------------------------------------------------
   declare
      F : Formula;
      S : Status;
   begin
      Build_Empty_Formula (F);
      Check (Solve (F) = Satisfiable, "empty formula SAT");
      Check (Is_Satisfiable (F), "Is_Satisfiable empty");

      Build_Empty_Clause (F);
      Check (Solve (F) = Unsatisfiable, "empty clause UNSAT");
      Check (not Is_Satisfiable (F), "not Is_Satisfiable □");

      Build_Contradictory_Units (F);
      Check (Solve (F) = Unsatisfiable, "(a)(¬a) UNSAT");

      Build_Two_Clause_Sat (F);
      S := Solve (F);
      Check (S = Satisfiable, "two-clause SAT");
      --  Caller formula untouched:
      Check (F.Num_Clauses = 2, "Solve does not mutate caller");

      Build_Pure_Only_Sat (F);
      Check (Solve (F) = Satisfiable, "pure-only SAT");

      Build_Small_3SAT_Sat (F);
      Check (Solve (F) = Satisfiable, "small 3SAT SAT");

      Build_Small_3SAT_Unsat (F);
      Check (Solve (F) = Unsatisfiable, "small 3SAT UNSAT");
   end;

   ---------------------------------------------------------------------
   Section ("8. Blow-up guard");
   ---------------------------------------------------------------------
   declare
      F : Formula;
      Ok : Boolean;
      S : Status;
   begin
      Build_Blowup_Risk (F);
      Check (F.Num_Clauses = 28, "blowup formula 28 clauses");
      Check (Count_Pos_Occurrences (F, 1) = 10, "10 pos");
      Check (Count_Neg_Occurrences (F, 1) = 10, "10 neg");
      Check (Find_Pure_Literal (F) = 0, "blowup has no pures");
      Check (Find_Unit_Literal (F) = 0, "blowup has no units");
      --  Direct eliminate var 1 must fail (144 > 96).
      Eliminate_Variable (F, 1, Ok);
      Check (not Ok, "Eliminate_Variable blow-up → not Ok");

      Build_Blowup_Risk (F);
      --  No units/pures (every var 2..13 appears ± with 1; var1 both).
      --  Choose_Variable picks 1 first → Solve returns Failed.
      S := Solve (F);
      Check (S = Failed, "Solve blow-up → Failed");
      Check (not Is_Satisfiable (F), "Is_Satisfiable false on Failed");
   end;

   ---------------------------------------------------------------------
   Section ("9. Choose_Variable / occurrence counts");
   ---------------------------------------------------------------------
   declare
      F : Formula;
      C : Clause;
   begin
      Clear (F);
      Check (Choose_Variable (F) = 0, "empty → choose 0");
      F.Num_Vars := 3;
      C := (Length => 2, Lits => [2, -3, others => 0]);
      Add_Clause (F, C);
      Check (Choose_Variable (F) = 2, "smallest occurring var=2");
      Check (Count_Pos_Occurrences (F, 2) = 1, "pos 2");
      Check (Count_Neg_Occurrences (F, 3) = 1, "neg 3");
      Check (Count_Pos_Occurrences (F, 1) = 0, "pos 1 zero");
   end;

   ---------------------------------------------------------------------
   Section ("10. From_DIMACS_Lite");
   ---------------------------------------------------------------------
   declare
      F : Formula;
      S : Status;
      Raised : Boolean;
   begin
      From_DIMACS_Lite (F,
        "p cnf 2 2" & ASCII.LF &
        "1 2 0" & ASCII.LF &
        "-1 2 0" & ASCII.LF);
      Check (F.Num_Vars = 2 and then F.Num_Clauses = 2, "DIMACS header");
      Check (Solve (F) = Satisfiable, "DIMACS two-clause SAT");

      From_DIMACS_Lite (F,
        "c comment" & ASCII.LF &
        "1 -2 3 0" & ASCII.LF &
        "-1 2 0" & ASCII.LF);
      Check (F.Num_Clauses = 2, "no-p DIMACS clauses");
      Check (F.Num_Vars = 3, "no-p DIMACS inferred vars");
      S := Solve (F);
      Check (S = Satisfiable, "no-p DIMACS sat");

      From_DIMACS_Lite (F,
        "p cnf 1 2" & ASCII.LF &
        "1 0" & ASCII.LF &
        "-1 0" & ASCII.LF);
      Check (Solve (F) = Unsatisfiable, "DIMACS (a)(¬a)");

      Raised := False;
      begin
         From_DIMACS_Lite (F, "p cnf 99 1" & ASCII.LF & "1 0" & ASCII.LF);
      exception
         when Capacity_Exceeded => Raised := True;
      end;
      Check (Raised, "DIMACS too many vars → Capacity_Exceeded");
   end;

   ---------------------------------------------------------------------
   Section ("11. Capacity / Set_Num_Vars edges");
   ---------------------------------------------------------------------
   declare
      F : Formula;
      C : Clause;
      Raised : Boolean;
   begin
      Clear (F);
      Set_Num_Vars (F, 2);
      C := (Length => 1, Lits => [1, others => 0]);
      Add_Clause (F, C);
      Raised := False;
      begin
         Set_Num_Vars (F, 0);
      exception
         when Invalid_Argument => Raised := True;
      end;
      Check (Raised, "Set_Num_Vars shrink past lit → Invalid_Argument");

      Clear (F);
      for I in 1 .. Max_Clauses loop
         C := (Length => 1, Lits => [1, others => 0]);
         --  duplicate var in successive unit clauses ok (same literal)
         Add_Clause (F, C);
      end loop;
      Check (F.Num_Clauses = Max_Clauses, "filled Max_Clauses");
      Raised := False;
      begin
         Add_Clause (F, C);
      exception
         when Capacity_Exceeded => Raised := True;
      end;
      Check (Raised, "Add_Clause past Max_Clauses");
   end;

   ---------------------------------------------------------------------
   Section ("12. Resolution elimination to SAT/UNSAT");
   ---------------------------------------------------------------------
   declare
      F : Formula;
      C : Clause;
      Ok : Boolean;
   begin
      --  (a∨b)(¬a∨¬b)(a∨¬b)(¬a∨b) — classic XOR-ish unsat on 2 vars
      --  Actually those four are all binary clauses = unsat (forces all).
      Clear (F);
      F.Num_Vars := 2;
      C := (Length => 2, Lits => [1, 2, others => 0]);
      Add_Clause (F, C);
      C := (Length => 2, Lits => [-1, -2, others => 0]);
      Add_Clause (F, C);
      C := (Length => 2, Lits => [1, -2, others => 0]);
      Add_Clause (F, C);
      C := (Length => 2, Lits => [-1, 2, others => 0]);
      Add_Clause (F, C);
      Check (Solve (F) = Unsatisfiable, "all 4 binaries UNSAT");

      --  Drop one → sat
      Clear (F);
      F.Num_Vars := 2;
      C := (Length => 2, Lits => [1, 2, others => 0]);
      Add_Clause (F, C);
      C := (Length => 2, Lits => [-1, -2, others => 0]);
      Add_Clause (F, C);
      C := (Length => 2, Lits => [1, -2, others => 0]);
      Add_Clause (F, C);
      Check (Solve (F) = Satisfiable, "3 of 4 binaries SAT");

      --  Manual elim path: eliminate both vars step by step on sat toy
      Build_Two_Clause_Sat (F);
      Eliminate_Variable (F, 1, Ok);
      Check (Ok, "manual elim 1");
      Eliminate_Variable (F, 2, Ok);
      Check (Ok, "manual elim 2");
      Check (F.Num_Clauses = 0, "after elim both → empty SAT");
   end;

   ---------------------------------------------------------------------
   Section ("13. Caps / capacity smoke");
   ---------------------------------------------------------------------
   declare
      F : Formula;
      C : Clause;
      Ok : Boolean;
      C1 : constant Clause :=
        (Length => Max_Clause_Len,
         Lits   => [1, 2, 3, 4, 5, 6, 7, 8]);
      C2 : constant Clause :=
        (Length => 2, Lits => [-1, 9, others => 0]);
      R : Clause;
      Taut : Boolean;
   begin
      Clear (F);
      Set_Num_Vars (F, Max_Vars);
      Check (F.Num_Vars = Max_Vars, "Set_Num_Vars(Max_Vars)");
      C := (Length => 1, Lits => [Make_Literal (Max_Vars, True), others => 0]);
      Add_Clause (F, C);
      Check (F.Clauses (1).Lits (1) = Make_Literal (Max_Vars, True),
             "lit at Max_Vars");
      Resolve_Clauses (C1, C2, 1, R, Taut, Ok);
      Check (Ok, "full-length resolve Ok");
      Check (R.Length = Max_Clause_Len, "resolvent at Max_Clause_Len");
      Check (not Clause_Mentions_Var (R, 1), "pivot eliminated from resolvent");
   end;

   ---------------------------------------------------------------------
   Section ("14. Apply_Unit_Literal / Apply_Pure_Literal direct");
   ---------------------------------------------------------------------
   declare
      F : Formula;
      Ok : Boolean;
      C : Clause;
   begin
      Clear (F);
      F.Num_Vars := 2;
      C := (Length => 2, Lits => [1, 2, others => 0]);
      Add_Clause (F, C);
      C := (Length => 2, Lits => [-1, 2, others => 0]);
      Add_Clause (F, C);
      Apply_Unit_Literal (F, 2, Ok);
      Check (Ok, "Apply_Unit +2 ok");
      Check (F.Num_Clauses = 0, "unit +2 deletes both (contain +2)");

      Build_Pure_Only_Sat (F);
      Apply_Pure_Literal (F, 1);
      Check (F.Num_Clauses = 0, "Apply_Pure +1 clears");
   end;

   ---------------------------------------------------------------------
   Section ("15. More SAT toys overlapping DPLL themes");
   ---------------------------------------------------------------------
   declare
      F : Formula;
      C : Clause;
   begin
      --  (¬x1 ∨ x2) ∧ (¬x1 ∨ ¬x2) ∧ (x1 ∨ x3) ∧ (x1 ∨ ¬x3) → unsat
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
      Check (Solve (F) = Unsatisfiable, "x1 forced both ways UNSAT");

      Clear (F);
      F.Num_Vars := 3;
      C := (Length => 2, Lits => [-1, 2, others => 0]);
      Add_Clause (F, C);
      C := (Length => 2, Lits => [-1, -2, others => 0]);
      Add_Clause (F, C);
      C := (Length => 2, Lits => [1, 3, others => 0]);
      Add_Clause (F, C);
      Check (Solve (F) = Satisfiable, "drop one → SAT");

      --  Single literal sat
      Clear (F);
      Add_Clause_From_Literals (F, [5, others => 0], 1);
      Check (Solve (F) = Satisfiable, "single unit SAT");

      --  Horn-ish chain sat
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
      Check (Solve (F) = Satisfiable, "Horn chain SAT");
   end;

   ---------------------------------------------------------------------
   Section ("16. Tautology skip / multi-elim");
   ---------------------------------------------------------------------
   declare
      F : Formula;
      C : Clause;
      Ok : Boolean;
   begin
      --  (a∨b)(¬a∨¬b) — elim a → (b∨¬b) tautology dropped → empty → SAT
      Clear (F);
      F.Num_Vars := 2;
      C := (Length => 2, Lits => [1, 2, others => 0]);
      Add_Clause (F, C);
      C := (Length => 2, Lits => [-1, -2, others => 0]);
      Add_Clause (F, C);
      Eliminate_Variable (F, 1, Ok);
      Check (Ok, "elim taut-only ok");
      Check (F.Num_Clauses = 0, "taut resolvent dropped → empty");
      Check (Solve (F) = Satisfiable, "residual SAT");

      --  Three vars independent units
      Clear (F);
      Add_Clause_From_Literals (F, [1, others => 0], 1);
      Add_Clause_From_Literals (F, [2, others => 0], 1);
      Add_Clause_From_Literals (F, [-3, others => 0], 1);
      Check (Solve (F) = Satisfiable, "three units SAT");
   end;

   ---------------------------------------------------------------------
   Section ("17. Status enumeration / Failed distinct");
   ---------------------------------------------------------------------
   declare
      F : Formula;
   begin
      Build_Two_Clause_Sat (F);
      Check (Status'Pos (Satisfiable) = 0, "Satisfiable pos");
      Check (Status'Pos (Unsatisfiable) = 1, "Unsatisfiable pos");
      Check (Status'Pos (Failed) = 2, "Failed pos");
      Check (Solve (F) /= Failed, "toy not Failed");
   end;

   ---------------------------------------------------------------------
   Section ("18. Clause length edge on resolve");
   ---------------------------------------------------------------------
   declare
      C1, C2, R : Clause;
      Taut, Ok : Boolean;
   begin
      --  Near-max length resolvent still ok
      C1 := (Length => 4, Lits => [1, 2, 3, 4, others => 0]);
      C2 := (Length => 4, Lits => [-1, 5, 6, 7, others => 0]);
      Resolve_Clauses (C1, C2, 1, R, Taut, Ok);
      Check (Ok and then not Taut and then R.Length = 6,
             "resolvent len 6 ok");

      --  Would exceed Max_Clause_Len=8
      C1 := (Length => 5, Lits => [1, 2, 3, 4, 5, others => 0]);
      C2 := (Length => 5, Lits => [-1, 6, 7, 8, 9, others => 0]);
      --  Wait Max_Vars=16 so 9 ok; resolvent length 8 exactly.
      Resolve_Clauses (C1, C2, 1, R, Taut, Ok);
      Check (Ok and then R.Length = 8, "resolvent len 8 at cap");

      C1 := (Length => 5, Lits => [1, 2, 3, 4, 5, others => 0]);
      --  Length 5 + Length 6 → 4+5=9 > Max_Clause_Len.
      C2 := (Length => 6, Lits => [-1, 6, 7, 8, 10, 11, others => 0]);
      Resolve_Clauses (C1, C2, 1, R, Taut, Ok);
      Check (not Ok, "resolvent len > 8 → not Ok");
   end;

   ---------------------------------------------------------------------
   Section ("19. Pure negative / mixed");
   ---------------------------------------------------------------------
   declare
      F : Formula;
      C : Clause;
      Changed : Boolean;
   begin
      Clear (F);
      F.Num_Vars := 2;
      C := (Length => 2, Lits => [-1, 2, others => 0]);
      Add_Clause (F, C);
      C := (Length => 2, Lits => [-1, -2, others => 0]);
      Add_Clause (F, C);
      Check (Find_Pure_Literal (F) = -1, "pure −1");
      Pure_Literal_Rule (F, Changed);
      Check (Changed and then F.Num_Clauses = 0, "pure −1 clears");
   end;

   ---------------------------------------------------------------------
   Section ("20. Batch Solve matrix");
   ---------------------------------------------------------------------
   declare
      F : Formula;
   begin
      for VV in Variable_Id range 1 .. 5 loop
         Clear (F);
         F.Num_Vars := VV;
         Add_Clause_From_Literals
           (F, [Make_Literal (VV, True), others => 0], 1);
         Check (Solve (F) = Satisfiable,
                "unit +" & Variable_Id'Image (VV) & " SAT");
      end loop;

      for VV in Variable_Id range 1 .. 5 loop
         Clear (F);
         F.Num_Vars := VV;
         Add_Clause_From_Literals
           (F, [Make_Literal (VV, True), others => 0], 1);
         Add_Clause_From_Literals
           (F, [Make_Literal (VV, False), others => 0], 1);
         Check (Solve (F) = Unsatisfiable,
                "units ±" & Variable_Id'Image (VV) & " UNSAT");
      end loop;
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
