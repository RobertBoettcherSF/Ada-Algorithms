with Ada.Text_IO; use Ada.Text_IO;
with Automated_Theorem_Proving; use Automated_Theorem_Proving;

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

   -- Helpers to build test clauses concisely
   function C (L1 : Literal) return Clause is 
      [1 => L1];
   function C (L1, L2 : Literal) return Clause is 
      [1 => L1, 2 => L2];
   function C (L1, L2, L3 : Literal) return Clause is 
      [1 => L1, 2 => L2, 3 => L3];
   function C_Empty return Clause is
      Result : Clause (1 .. 0);
   begin
      return Result;
   end C_Empty;

   -- Local helper definition used in Test 9 & 10
   function Contains_Clause_Helper (Frm : CNF_Formula; Tgt : Clause) return Boolean is
      Found : Boolean;
   begin
      for C of Frm loop
         if C'Length = Tgt'Length then
            Found := True;
            for L_Tgt of Tgt loop
               if not Contains_Literal (C, L_Tgt) then
                  Found := False;
                  exit;
               end if;
            end loop;
            if Found then return True; end if;
         end if;
      end loop;
      return False;
   end Contains_Clause_Helper;

   Empty_F : CNF_Formula;
   F       : CNF_Formula;
   F2      : CNF_Formula;
begin
   -------------------------------------------------------------------------
   Put_Line ("TEST 1 — DPLL Base Cases");
   Check ("1.1 DPLL resolves Empty Formula as True", 
          Is_Satisfiable_DPLL (Empty_F));
   
   F.Clear;
   F.Append (C_Empty);
   Check ("1.2 DPLL resolves Formula with Empty Clause as False", 
          not Is_Satisfiable_DPLL (F));
   
   F.Clear;
   F.Append (C (Pos (1)));
   Check ("1.3 DPLL resolves Valid Unit Clause as True", 
          Is_Satisfiable_DPLL (F));

   -------------------------------------------------------------------------
   Put_Line ("TEST 2 — DP Resolution Base Cases");
   Check ("2.1 DP_Res resolves Empty Formula as True", 
          Is_Satisfiable_DP_Resolution (Empty_F));
   
   F.Clear;
   F.Append (C_Empty);
   Check ("2.2 DP_Res resolves Formula with Empty Clause as False", 
          not Is_Satisfiable_DP_Resolution (F));
   
   F.Clear;
   F.Append (C (Pos (1)));
   Check ("2.3 DP_Res resolves Valid Unit Clause as True", 
          Is_Satisfiable_DP_Resolution (F));

   -------------------------------------------------------------------------
   Put_Line ("TEST 3 — Exhaustive Evaluation Base Cases");
   Check ("3.1 Exh resolves Empty Formula as True", 
          Is_Satisfiable_Exhaustive (Empty_F, 1));
   
   F.Clear;
   F.Append (C_Empty);
   Check ("3.2 Exh resolves Formula with Empty Clause as False", 
          not Is_Satisfiable_Exhaustive (F, 1));
   
   F.Clear;
   F.Append (C (Pos (1)));
   Check ("3.3 Exh resolves Valid Unit Clause as True", 
          Is_Satisfiable_Exhaustive (F, 1));

   -------------------------------------------------------------------------
   Put_Line ("TEST 4 — DPLL Complex Satisfiable");
   F.Clear;
   F.Append (C (Pos (1), Pos (2)));     -- (A or B)
   F.Append (C (Pos (1), Neg (2)));     -- (A or not B)
   Check ("4.1 DPLL evaluates (A or B) and (A or not B) to True", 
          Is_Satisfiable_DPLL (F));
   
   F.Clear;
   F.Append (C (Pos (1)));              -- (A)
   F.Append (C (Neg (1), Pos (2)));     -- (not A or B)
   F.Append (C (Neg (2), Pos (3)));     -- (not B or C)
   Check ("4.2 DPLL evaluates chain deduction to True", 
          Is_Satisfiable_DPLL (F));

   F.Clear;
   F.Append (C (Pos (1), Pos (2)));     -- (A or B)
   F.Append (C (Neg (1), Pos (2)));     -- (not A or B)
   Check ("4.3 DPLL handles overlapping truths correctly", 
          Is_Satisfiable_DPLL (F));

   -------------------------------------------------------------------------
   Put_Line ("TEST 5 — DPLL Complex Unsatisfiable");
   F.Clear;
   F.Append (C (Pos (1)));
   F.Append (C (Neg (1)));
   Check ("5.1 DPLL evaluates (A) and (not A) to False", 
          not Is_Satisfiable_DPLL (F));
   
   F.Clear;
   F.Append (C (Pos (1), Pos (2)));
   F.Append (C (Pos (1), Neg (2)));
   F.Append (C (Neg (1), Pos (2)));
   F.Append (C (Neg (1), Neg (2)));
   Check ("5.2 DPLL evaluates exhaustive contradiction to False", 
          not Is_Satisfiable_DPLL (F));

   F.Clear;
   F.Append (C (Pos (1)));
   F.Append (C (Pos (2)));
   F.Append (C (Neg (1), Neg (2)));
   Check ("5.3 DPLL detects contradiction deep in chain", 
          not Is_Satisfiable_DPLL (F));

   -------------------------------------------------------------------------
   Put_Line ("TEST 6 — DP Resolution Complex Satisfiable");
   F.Clear;
   F.Append (C (Pos (1), Pos (2)));
   F.Append (C (Pos (1), Neg (2)));
   Check ("6.1 DP_Res evaluates (A or B) and (A or not B) to True", 
          Is_Satisfiable_DP_Resolution (F));
   
   F.Clear;
   F.Append (C (Pos (1)));
   F.Append (C (Neg (1), Pos (2)));
   F.Append (C (Neg (2), Pos (3)));
   Check ("6.2 DP_Res evaluates chain deduction to True", 
          Is_Satisfiable_DP_Resolution (F));

   F.Clear;
   F.Append (C (Pos (1), Pos (2)));
   F.Append (C (Neg (1), Pos (2)));
   Check ("6.3 DP_Res handles overlapping truths correctly", 
          Is_Satisfiable_DP_Resolution (F));

   -------------------------------------------------------------------------
   Put_Line ("TEST 7 — DP Resolution Complex Unsatisfiable");
   F.Clear;
   F.Append (C (Pos (1)));
   F.Append (C (Neg (1)));
   Check ("7.1 DP_Res evaluates (A) and (not A) to False", 
          not Is_Satisfiable_DP_Resolution (F));
   
   F.Clear;
   F.Append (C (Pos (1), Pos (2)));
   F.Append (C (Pos (1), Neg (2)));
   F.Append (C (Neg (1), Pos (2)));
   F.Append (C (Neg (1), Neg (2)));
   Check ("7.2 DP_Res evaluates exhaustive contradiction to False", 
          not Is_Satisfiable_DP_Resolution (F));

   F.Clear;
   F.Append (C (Pos (1)));
   F.Append (C (Pos (2)));
   F.Append (C (Neg (1), Neg (2)));
   Check ("7.3 DP_Res detects contradiction deep in chain", 
          not Is_Satisfiable_DP_Resolution (F));

   -------------------------------------------------------------------------
   Put_Line ("TEST 8 — Exhaustive Complex Behavior");
   F.Clear;
   F.Append (C (Pos (1), Pos (2)));
   F.Append (C (Pos (1), Neg (2)));
   Check ("8.1 Exh handles complex satisfiable constraints", 
          Is_Satisfiable_Exhaustive (F, 2));

   F.Clear;
   F.Append (C (Pos (1)));
   F.Append (C (Pos (2)));
   F.Append (C (Neg (1), Neg (2)));
   Check ("8.2 Exh rigorously detects hidden UNSAT", 
          not Is_Satisfiable_Exhaustive (F, 2));

   F.Clear;
   F.Append (C (Pos (1), Pos (2), Pos (3)));
   F.Append (C (Neg (2), Neg (3)));
   Check ("8.3 Exh handles 3-variable logic correctly", 
          Is_Satisfiable_Exhaustive (F, 3));

   -------------------------------------------------------------------------
   Put_Line ("TEST 9 — Unit Propagation Mechanics");
   F.Clear;
   F.Append (C (Pos (1), Pos (2)));      -- (A or B)
   F.Append (C (Neg (1), Pos (3)));      -- (not A or C)
   F.Append (C (Neg (2), Pos (4)));      -- (not B or D)
   F2 := Simplify_Unit_Propagation (F, Pos (1)); -- Set A = True
   
   Check ("9.1 Unit propagation removes satisfied clauses (A or B)", 
          not Contains_Clause_Helper (F2, C (Pos (1), Pos (2))));
          
   Check ("9.2 Unit propagation shortens clauses with false literals (not A or C) -> (C)", 
          Contains_Clause_Helper (F2, C (Pos (3))));
          
   Check ("9.3 Unit propagation leaves unrelated clauses intact", 
          Contains_Clause_Helper (F2, C (Neg (2), Pos (4))));

   -------------------------------------------------------------------------
   Put_Line ("TEST 10 — Pure Literal Elimination");
   F.Clear;
   F.Append (C (Pos (1), Pos (2)));
   F.Append (C (Neg (2), Pos (3)));
   F2 := Simplify_Pure_Literal (F, Pos (1)); -- 'A' is pure
   
   Check ("10.1 Pure literal eliminates clauses containing it", 
          not Contains_Clause_Helper (F2, C (Pos (1), Pos (2))));
          
   Check ("10.2 Pure literal leaves other clauses intact", 
          Contains_Clause_Helper (F2, C (Neg (2), Pos (3))));
          
   Check ("10.3 Pure literal reduces formula size correctly", 
          Natural (F2.Length) = 1);

   -------------------------------------------------------------------------
   Put_Line ("TEST 11 — Resolution & Tautology detection");
   declare
      Res : constant Clause := Resolve_Clauses (C (Pos (1), Pos (2)), C (Neg (1), Pos (3)), 1);
   begin
      Check ("11.1 Resolve correctly drops pivot and combines rest", 
             Res'Length = 2 and then Contains_Literal (Res, Pos (2)) and then Contains_Literal (Res, Pos (3)));
   end;
   
   declare
      Res : constant Clause := Resolve_Clauses (C (Pos (1), Pos (2)), C (Neg (1), Neg (2)), 1);
   begin
      Check ("11.2 Resolve handles tautological outcomes", 
             Is_Tautology (Res));
   end;
   
   Check ("11.3 Is_Tautology accurately identifies standard clauses as false", 
          not Is_Tautology (C (Pos (1), Pos (2))));

   -------------------------------------------------------------------------
   Put_Line ("TEST 12 — Remove Duplicates Behavior");
   declare
      C_Dup : constant Clause := [1 => Pos (1), 2 => Pos (1)];
      C_Cln : constant Clause := Remove_Duplicates (C_Dup);
   begin
      Check ("12.1 Remove_Duplicates shrinks array to 1", C_Cln'Length = 1);
      Check ("12.2 Remove_Duplicates keeps valid literal", C_Cln (C_Cln'First) = Pos (1));
   end;
   
   declare
      C_Mix : constant Clause := [1 => Pos (1), 2 => Neg (2), 3 => Pos (1), 4 => Neg (2)];
      C_Cln : constant Clause := Remove_Duplicates (C_Mix);
   begin
      Check ("12.3 Remove_Duplicates works symmetrically on multi-variables", C_Cln'Length = 2);
   end;

   -------------------------------------------------------------------------
   Put_Line ("TEST 13 — Edge Cases & Safeties");
   F.Clear;
   F.Append (C (Pos (10), Pos (100), Pos (1000))); -- large skipped ranges
   Check ("13.1 Resolvers handle sparse variable IDs gracefully", 
          Is_Satisfiable_DPLL (F) and then Is_Satisfiable_DP_Resolution (F));

   F.Clear;
   F.Append (C (Neg (1), Neg (2), Neg (3)));
   Check ("13.2 Formula with exclusively negative literals resolves True", 
          Is_Satisfiable_DPLL (F));

   declare
   begin
      -- Dynamic predicate or runtime fault protection check: 
      -- A literal with Var=0 cannot be constructed due to Positive constraint.
      -- So we simulate pushing an empty clause dynamically to SAT.
      F.Clear;
      F.Append (C (Pos (1)));
      F.Append (C_Empty);
      Check ("13.3 Satisfiable formula ruined by one empty clause evaluates False", 
             not Is_Satisfiable_DPLL (F));
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");

end Tests;
