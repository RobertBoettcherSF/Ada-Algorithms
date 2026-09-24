with Ada.Text_IO; use Ada.Text_IO;
with CDCL;        use CDCL;

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

   procedure Add_C1 (F : in out Formula; L1 : Literal) is
      C : Clause;
   begin
      C.Append (L1);
      Add_Clause (F, C);
   end Add_C1;

   procedure Add_C2 (F : in out Formula; L1, L2 : Literal) is
      C : Clause;
   begin
      C.Append (L1);
      C.Append (L2);
      Add_Clause (F, C);
   end Add_C2;

   procedure Add_C3 (F : in out Formula; L1, L2, L3 : Literal) is
      C : Clause;
   begin
      C.Append (L1);
      C.Append (L2);
      C.Append (L3);
      Add_Clause (F, C);
   end Add_C3;

begin
   Put_Line ("TEST 1 — Empty Formula");
   declare
      F : Formula;
      A : Assignment_Array (1 .. 1);
      S : Solve_Status;
   begin
      Init_Formula (F, 1);
      S := Solve_Basic (F, A);
      Check ("1.1 Status Satisfiable", S = Satisfiable);
      Check ("1.2 Validation passes", Is_Satisfied (F, A));
      Check ("1.3 Assignment mapped properly", A'Length = 1);
   end;

   Put_Line ("TEST 2 — Single Var Positive");
   declare
      F : Formula;
      A : Assignment_Array (1 .. 1);
      S : Solve_Status;
   begin
      Init_Formula (F, 1);
      Add_C1 (F, 1);
      S := Solve_Basic (F, A);
      Check ("2.1 Status Satisfiable", S = Satisfiable);
      Check ("2.2 A(1) is True", A (1) = True);
      Check ("2.3 Validation passes", Is_Satisfied (F, A));
   end;

   Put_Line ("TEST 3 — Single Var Negative");
   declare
      F : Formula;
      A : Assignment_Array (1 .. 1);
      S : Solve_Status;
   begin
      Init_Formula (F, 1);
      Add_C1 (F, -1);
      S := Solve_Basic (F, A);
      Check ("3.1 Status Satisfiable", S = Satisfiable);
      Check ("3.2 A(1) is False", A (1) = False);
      Check ("3.3 Validation passes", Is_Satisfied (F, A));
   end;

   Put_Line ("TEST 4 — Single Var UNSAT");
   declare
      F : Formula;
      A : Assignment_Array (1 .. 1);
      S : Solve_Status;
   begin
      Init_Formula (F, 1);
      Add_C1 (F, 1);
      Add_C1 (F, -1);
      S := Solve_Basic (F, A);
      Check ("4.1 Status Unsatisfiable", S = Unsatisfiable);
      Check ("4.2 Formula is correctly built", Natural(F.Clauses.Length) = 2);
      Check ("4.3 Length correct", A'Length = 1);
   end;

   Put_Line ("TEST 5 — Two Vars SAT");
   declare
      F : Formula;
      A : Assignment_Array (1 .. 2);
      S : Solve_Status;
   begin
      Init_Formula (F, 2);
      Add_C2 (F, 1, 2);
      Add_C1 (F, -1);
      S := Solve_Basic (F, A);
      Check ("5.1 Status Satisfiable", S = Satisfiable);
      Check ("5.2 A(1) is False", A (1) = False);
      Check ("5.3 A(2) is True", A (2) = True);
   end;

   Put_Line ("TEST 6 — Two Vars UNSAT");
   declare
      F : Formula;
      A : Assignment_Array (1 .. 2);
      S : Solve_Status;
   begin
      Init_Formula (F, 2);
      Add_C2 (F, 1, 2);
      Add_C2 (F, -1, -2);
      Add_C2 (F, 1, -2);
      Add_C2 (F, -1, 2);
      S := Solve_Basic (F, A);
      Check ("6.1 Status Unsatisfiable", S = Unsatisfiable);
      Check ("6.2 Formula constraint checking", Natural(F.Clauses.Length) = 4);
      Check ("6.3 Valid sizes maintained", A'Length = 2);
   end;

   Put_Line ("TEST 7 — Three Vars Chain SAT");
   declare
      F : Formula;
      A : Assignment_Array (1 .. 3);
      S : Solve_Status;
   begin
      Init_Formula (F, 3);
      Add_C3 (F, 1, 2, 3);
      Add_C1 (F, -1);
      S := Solve_Basic (F, A);
      Check ("7.1 Status Satisfiable", S = Satisfiable);
      Check ("7.2 Validation passes", Is_Satisfied (F, A));
      Check ("7.3 A(1) forced to False", A (1) = False);
   end;

   Put_Line ("TEST 8 — Three Vars Chain UNSAT");
   declare
      F : Formula;
      A : Assignment_Array (1 .. 3);
      S : Solve_Status;
   begin
      Init_Formula (F, 3);
      Add_C2 (F, -1, 2);
      Add_C2 (F, -2, 3);
      Add_C1 (F, 1);
      Add_C1 (F, -3);
      S := Solve_Basic (F, A);
      Check ("8.1 Status Unsatisfiable", S = Unsatisfiable);
      Check ("8.2 Length is correct", A'Length = 3);
      Check ("8.3 Four clauses total", Natural(F.Clauses.Length) = 4);
   end;

   Put_Line ("TEST 9 — Restarts Variant SAT");
   declare
      F : Formula;
      A : Assignment_Array (1 .. 4);
      S : Solve_Status;
   begin
      Init_Formula (F, 4);
      Add_C3 (F, 1, 2, 3);
      Add_C2 (F, -2, 4);
      S := Solve_With_Restarts (F, A, Restart_Interval => 2);
      Check ("9.1 Status Satisfiable", S = Satisfiable);
      Check ("9.2 Validation passes", Is_Satisfied (F, A));
      Check ("9.3 Variables correct", A'Length = 4);
   end;

   Put_Line ("TEST 10 — Restarts Variant UNSAT");
   declare
      F : Formula;
      A : Assignment_Array (1 .. 3);
      S : Solve_Status;
   begin
      Init_Formula (F, 3);
      Add_C2 (F, 1, 2); Add_C2 (F, -1, -2);
      Add_C2 (F, 1, -2); Add_C2 (F, -1, 2);
      S := Solve_With_Restarts (F, A, Restart_Interval => 1);
      Check ("10.1 Status Unsatisfiable", S = Unsatisfiable);
      Check ("10.2 Formula constraint checking", Natural(F.Clauses.Length) = 4);
      Check ("10.3 Restarts run cleanly", A'Length = 3);
   end;

   Put_Line ("TEST 11 — Deletion Variant SAT");
   declare
      F : Formula;
      A : Assignment_Array (1 .. 4);
      S : Solve_Status;
   begin
      Init_Formula (F, 4);
      Add_C3 (F, 1, 2, 3);
      Add_C2 (F, -2, 4);
      S := Solve_With_Clause_Deletion (F, A, Max_Learned => 2);
      Check ("11.1 Status Satisfiable", S = Satisfiable);
      Check ("11.2 Validation passes", Is_Satisfied (F, A));
      Check ("11.3 Variables correct", A'Length = 4);
   end;

   Put_Line ("TEST 12 — Deletion Variant UNSAT");
   declare
      F : Formula;
      A : Assignment_Array (1 .. 3);
      S : Solve_Status;
   begin
      Init_Formula (F, 3);
      Add_C2 (F, 1, 2); Add_C2 (F, -1, -2);
      Add_C2 (F, 1, -2); Add_C2 (F, -1, 2);
      S := Solve_With_Clause_Deletion (F, A, Max_Learned => 1);
      Check ("12.1 Status Unsatisfiable", S = Unsatisfiable);
      Check ("12.2 Formula constraint checking", Natural(F.Clauses.Length) = 4);
      Check ("12.3 Deletion loop run cleanly", A'Length = 3);
   end;

   Put_Line ("TEST 13 — Exception: Bad Literal");
   declare
      F : Formula;
      Caught : Boolean := False;
   begin
      Init_Formula (F, 1);
      begin
         Add_C1 (F, 0);
      exception
         when Bad_Literal => Caught := True;
      end;
      Check ("13.1 Bad_Literal caught for 0", Caught);
      Check ("13.2 Formula unchanged", Natural(F.Clauses.Length) = 0);
      Check ("13.3 Variables count intact", F.Variables_Count = 1);
   end;

   Put_Line ("TEST 14 — Exception: Invalid Formula (Out of Bounds Var)");
   declare
      F : Formula;
      Caught : Boolean := False;
   begin
      Init_Formula (F, 1);
      begin
         Add_C1 (F, 5);
      exception
         when Invalid_Formula => Caught := True;
      end;
      Check ("14.1 Invalid_Formula caught for exceeding bounds", Caught);
      Check ("14.2 Formula unchanged", Natural(F.Clauses.Length) = 0);
      Check ("14.3 Variables count intact", F.Variables_Count = 1);
   end;

   Put_Line ("TEST 15 — Complex Manual Evaluation Validation");
   declare
      F : Formula;
      A : Assignment_Array (1 .. 4) := [True, False, True, False];
   begin
      Init_Formula (F, 4);
      Add_C3 (F, 1, 2, 4);
      Add_C2 (F, -2, -4);
      Check ("15.1 Formula manual init valid", Natural(F.Clauses.Length) = 2);
      Check ("15.2 Validation logic properly flags SAT", Is_Satisfied (F, A));
      
      A (1) := False; A (2) := False; A (4) := False;
      Check ("15.3 Validation logic properly flags UNSAT when tweaked", not Is_Satisfied (F, A));
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
