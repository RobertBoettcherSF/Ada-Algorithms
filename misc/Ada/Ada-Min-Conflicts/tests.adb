--  Standalone test suite for Min_Conflicts (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with Min_Conflicts; use Min_Conflicts;

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

   --  Known solved N=4: columns [2,4,1,3] (1-based).
   function Solved_4 return Board is
   begin
      return [2, 4, 1, 3];
   end Solved_4;

   --  Known solved N=8 (one standard solution).
   function Solved_8 return Board is
   begin
      return [1, 5, 8, 6, 3, 7, 2, 4];
   end Solved_8;

   --  All queens on main diagonal — many conflicts.
   function Diagonal_N (N : Queens_N) return Board is
      B : Board (1 .. N);
   begin
      for R in 1 .. N loop
         B (R) := R;
      end loop;
      return B;
   end Diagonal_N;

   --  All queens in column 1.
   function Same_Column_N (N : Queens_N) return Board is
      B : Board (1 .. N);
   begin
      for R in 1 .. N loop
         B (R) := 1;
      end loop;
      return B;
   end Same_Column_N;

begin
   Put_Line ("Min_Conflicts test suite");
   Put_Line ("========================");

   ---------------------------------------------------------------------
   Section ("1. Default_Parameters / RNG");
   ---------------------------------------------------------------------
   declare
      P          : Parameters;
      S1, S2, S3 : RNG_State;
      A, B, C    : Natural;
      All_In     : Boolean := True;
      Saw_Diff   : Boolean := False;
      Prev       : Natural := 0;
   begin
      P := Default_Parameters;
      Check (P.Max_Steps = 1_000, "default Max_Steps");
      Check (P.Seed = 1, "default Seed");
      Check (P.Restarts = 0, "default Restarts");
      P := Default_Parameters (Max_Steps => 50, Seed => 7, Restarts => 3);
      Check (P.Max_Steps = 50, "custom Max_Steps");
      Check (P.Seed = 7, "custom Seed");
      Check (P.Restarts = 3, "custom Restarts");

      Seed_RNG (S1, 42);
      Seed_RNG (S2, 42);
      Seed_RNG (S3, 99);
      A := Next_Natural (S1, 1, 100);
      B := Next_Natural (S2, 1, 100);
      C := Next_Natural (S3, 1, 100);
      Check (A = B, "same seed -> same draw");
      Check (A /= C, "different seeds differ");

      Seed_RNG (S1, 0);
      A := Next_Natural (S1, 1, 10);
      Check (A in 1 .. 10, "seed 0 in range");

      Seed_RNG (S1, 11);
      for I in 1 .. 40 loop
         A := Next_Natural (S1, 1, 8);
         if A < 1 or else A > 8 then
            All_In := False;
         end if;
         if I > 1 and then A /= Prev then
            Saw_Diff := True;
         end if;
         Prev := A;
      end loop;
      Check (All_In, "40 draws in 1..8");
      Check (Saw_Diff, "RNG produces variation");

      Seed_RNG (S1, 3);
      Check (Next_Natural (S1, 5, 5) = 5, "Next_Natural Lo=Hi");
   end;

   ---------------------------------------------------------------------
   Section ("2. Conflict counting on known boards");
   ---------------------------------------------------------------------
   declare
      B4  : constant Board := Solved_4;
      B8  : constant Board := Solved_8;
      D4  : constant Board := Diagonal_N (4);
      S4  : constant Board := Same_Column_N (4);
      D8  : constant Board := Diagonal_N (8);
   begin
      Check (Conflict_Count (B4) = 0, "solved-4 Conflict_Count=0");
      Check (Is_Solved (B4), "solved-4 Is_Solved");
      Check (Variable_Conflicts (B4, 1) = 0, "solved-4 row1 vc=0");
      Check (Variable_Conflicts (B4, 2) = 0, "solved-4 row2 vc=0");
      Check (Variable_Conflicts (B4, 3) = 0, "solved-4 row3 vc=0");
      Check (Variable_Conflicts (B4, 4) = 0, "solved-4 row4 vc=0");

      Check (Conflict_Count (B8) = 0, "solved-8 Conflict_Count=0");
      Check (Is_Solved (B8), "solved-8 Is_Solved");

      --  Diagonal 4: pairs (1,2),(1,3),(1,4),(2,3),(2,4),(3,4) all attack
      --  on the main diagonal → 6 attacking pairs.
      Check (Conflict_Count (D4) = 6, "diagonal-4 Conflict_Count=6");
      Check (not Is_Solved (D4), "diagonal-4 not solved");
      Check (Variable_Conflicts (D4, 1) = 3, "diagonal-4 row1 vc=3");
      Check (Variable_Conflicts (D4, 2) = 3, "diagonal-4 row2 vc=3");
      Check (Variable_Conflicts (D4, 3) = 3, "diagonal-4 row3 vc=3");
      Check (Variable_Conflicts (D4, 4) = 3, "diagonal-4 row4 vc=3");

      --  Same column: C(4,2)=6 column pairs, no diagonals (same col already).
      Check (Conflict_Count (S4) = 6, "same-col-4 Conflict_Count=6");
      Check (Variable_Conflicts (S4, 1) = 3, "same-col-4 row1 vc=3");

      Check (Conflict_Count (D8) = 28, "diagonal-8 Conflict_Count=C(8,2)=28");
      Check (not Is_Solved (D8), "diagonal-8 not solved");
   end;

   ---------------------------------------------------------------------
   Section ("3. Partial / mixed conflict boards");
   ---------------------------------------------------------------------
   declare
      --  N=4 board [1,2,1,4]:
      --  Pairs: (1,2) diag, (1,3) col, (1,4) diag, (2,3) diag, (2,4) diag
      --  → 5 pairs. vc: row1=3, row2=3, row3=2, row4=2.
      B : constant Board := [1, 2, 1, 4];
   begin
      Check (Conflict_Count (B) = 5, "mixed board Conflict_Count=5");
      Check (Variable_Conflicts (B, 1) = 3, "mixed row1 vc=3");
      Check (Variable_Conflicts (B, 2) = 3, "mixed row2 vc=3");
      Check (Variable_Conflicts (B, 3) = 2, "mixed row3 vc=2");
      Check (Variable_Conflicts (B, 4) = 2, "mixed row4 vc=2");
      Check (not Is_Solved (B), "mixed not solved");
   end;

   ---------------------------------------------------------------------
   Section ("4. Min_Conflict_Value / Pick_Conflicted_Variable");
   ---------------------------------------------------------------------
   declare
      B     : Board := Same_Column_N (4);
      State : RNG_State;
      Col   : Column_Index;
      Row   : Natural;
      Conf  : Natural;
      Best  : Natural;
   begin
      Seed_RNG (State, 1);
      --  For row 1 on all-col-1 board, best move is any col ≠ 1 that
      --  minimises remaining attacks. Col 1 has 3 conflicts; others fewer.
      Col := Min_Conflict_Value (B, 1, State);
      declare
         Trial : Board := B;
      begin
         Trial (1) := Col;
         Conf := Variable_Conflicts (Trial, 1);
      end;
      Best := Natural'Last;
      for C in 1 .. 4 loop
         declare
            Trial : Board := B;
            Vc    : Natural;
         begin
            Trial (1) := C;
            Vc := Variable_Conflicts (Trial, 1);
            if Vc < Best then
               Best := Vc;
            end if;
         end;
      end loop;
      Check (Conf = Best, "Min_Conflict_Value achieves min");
      Check (Col in 1 .. 4, "Min_Conflict_Value in range");

      Seed_RNG (State, 5);
      Row := Pick_Conflicted_Variable (B, State);
      Check (Row in 1 .. 4, "Pick_Conflicted on conflicted board");
      Check (Variable_Conflicts (B, Row) > 0, "picked row is conflicted");

      B := Solved_4;
      Seed_RNG (State, 5);
      Row := Pick_Conflicted_Variable (B, State);
      Check (Row = 0, "Pick_Conflicted on solved returns 0");
   end;

   ---------------------------------------------------------------------
   Section ("5. Step on known boards");
   ---------------------------------------------------------------------
   declare
      B     : Board := Same_Column_N (4);
      State : RNG_State;
      Moved : Boolean;
      Before, After : Natural;
   begin
      Seed_RNG (State, 2);
      Before := Conflict_Count (B);
      Step (B, State, Moved);
      After := Conflict_Count (B);
      Check (Moved, "Step moves on conflicted board");
      Check (After <= Before, "Step does not increase conflicts (heuristic)");
      --  Note: min-conflicts can plateau; After <= Before is typical but
      --  for a single variable reassignment to its min, conflicts for that
      --  variable cannot increase vs its old value's conflicts_at — total
      --  pair count is non-increasing when choosing true min for that var.
      Check (After < Before or else After = Before,
             "Step non-increasing total");

      B := Solved_4;
      Seed_RNG (State, 2);
      Step (B, State, Moved);
      Check (not Moved, "Step on solved does not move");
      Check (Is_Solved (B), "solved board stays solved");
   end;

   ---------------------------------------------------------------------
   Section ("6. Random_Board / Greedy_Board");
   ---------------------------------------------------------------------
   declare
      B1, B2 : Board (1 .. 8);
      State  : RNG_State;
      Ok     : Boolean := True;
   begin
      Seed_RNG (State, 10);
      Random_Board (B1, 8, State);
      for R in 1 .. 8 loop
         if B1 (R) not in 1 .. 8 then
            Ok := False;
         end if;
      end loop;
      Check (Ok, "Random_Board values in 1..8");

      Seed_RNG (State, 10);
      Random_Board (B2, 8, State);
      Check (B1 = B2, "Random_Board deterministic for same seed stream");

      Seed_RNG (State, 20);
      Greedy_Board (B1, 8, State);
      Ok := True;
      for R in 1 .. 8 loop
         if B1 (R) not in 1 .. 8 then
            Ok := False;
         end if;
      end loop;
      Check (Ok, "Greedy_Board values in 1..8");
      --  Greedy start should have far fewer conflicts than worst case 28.
      Check (Conflict_Count (B1) < 28, "Greedy_Board fewer than diagonal");
      Check (Conflict_Count (B1) <= 8, "Greedy_Board reasonably low");
   end;

   ---------------------------------------------------------------------
   Section ("7. Minimize_Conflicts from known start");
   ---------------------------------------------------------------------
   declare
      B      : Board := Diagonal_N (4);
      Params : Parameters;
      Res    : Solve_Result;
   begin
      Params := Default_Parameters (Max_Steps => 200, Seed => 3, Restarts => 0);
      Minimize_Conflicts (B, Params, Res);
      Check (Res.Solved, "Minimize N=4 diagonal solved");
      Check (Is_Solved (B), "Minimize leaves solved board");
      Check (Res.Final_Conflicts = 0, "Minimize Final_Conflicts=0");
      Check (Res.Steps_Used > 0, "Minimize used some steps");
      Check (Res.Steps_Used <= 200, "Minimize within budget");
   end;

   declare
      B      : Board := Solved_4;
      Params : Parameters;
      Res    : Solve_Result;
   begin
      Params := Default_Parameters (Max_Steps => 10, Seed => 1);
      Minimize_Conflicts (B, Params, Res);
      Check (Res.Solved, "Minimize already-solved stays solved");
      Check (Res.Steps_Used = 0, "Minimize already-solved Steps=0");
   end;

   ---------------------------------------------------------------------
   Section ("8. Unsolved path Max_Steps=0");
   ---------------------------------------------------------------------
   declare
      B      : Board (1 .. 4);
      Params : Parameters;
      Res    : Solve_Result;
   begin
      Params :=
        Default_Parameters (Max_Steps => 0, Seed => 1, Restarts => 0);
      Solve_N_Queens (4, Params, B, Res);
      --  With Max_Steps=0 no Step runs; a greedy start may already be
      --  solved (legal). Always check Steps / Restarts / consistency.
      Check (Res.Steps_Used = 0, "Max_Steps=0 Steps_Used=0");
      Check (Res.Final_Conflicts = Conflict_Count (B),
             "Final_Conflicts matches board");
      Check (Res.Restarts_Used = 0, "Max_Steps=0 Restarts_Used=0");
      Check (Res.Solved = (Res.Final_Conflicts = 0),
             "Max_Steps=0 Solved iff zero conflicts");
   end;

   declare
      B      : Board := Diagonal_N (4);
      Params : Parameters;
      Res    : Solve_Result;
   begin
      Params := Default_Parameters (Max_Steps => 0, Seed => 9);
      Minimize_Conflicts (B, Params, Res);
      Check (not Res.Solved, "Minimize Max_Steps=0 on diagonal fails");
      Check (Res.Steps_Used = 0, "Minimize Max_Steps=0 Steps=0");
      Check (Res.Final_Conflicts = 6, "Minimize Max_Steps=0 keeps 6");
   end;

   ---------------------------------------------------------------------
   Section ("9. Solve_N_Queens N=4 reliable");
   ---------------------------------------------------------------------
   declare
      B      : Board (1 .. 4);
      Params : Parameters;
      Res    : Solve_Result;
      All_Ok : Boolean := True;
   begin
      for Seed in 1 .. 8 loop
         Params :=
           Default_Parameters
             (Max_Steps => 2_000, Seed => Seed, Restarts => 200);
         Solve_N_Queens (4, Params, B, Res);
         if not Res.Solved or else not Is_Solved (B) then
            All_Ok := False;
         end if;
         Check (Res.Solved, "Solve N=4 seed" & Seed'Image);
      end loop;
      Check (All_Ok, "Solve N=4 all 8 seeds");
   end;

   ---------------------------------------------------------------------
   Section ("10. Solve_N_Queens N=8 reliable");
   ---------------------------------------------------------------------
   declare
      B      : Board (1 .. 8);
      Params : Parameters;
      Res    : Solve_Result;
      All_Ok : Boolean := True;
   begin
      for Seed in 1 .. 6 loop
         Params :=
           Default_Parameters
             (Max_Steps => 5_000, Seed => Seed, Restarts => 50);
         Solve_N_Queens (8, Params, B, Res);
         if not Res.Solved or else Conflict_Count (B) /= 0 then
            All_Ok := False;
         end if;
         Check (Res.Solved, "Solve N=8 seed" & Seed'Image);
      end loop;
      Check (All_Ok, "Solve N=8 all 6 seeds");
   end;

   ---------------------------------------------------------------------
   Section ("11. Solve N=5 / N=6 / N=10 smoke");
   ---------------------------------------------------------------------
   declare
      Params : Parameters;
      Res    : Solve_Result;
   begin
      declare
         B5 : Board (1 .. 5);
      begin
         Params :=
           Default_Parameters
             (Max_Steps => 1_000, Seed => 4, Restarts => 5);
         Solve_N_Queens (5, Params, B5, Res);
         Check (Res.Solved, "Solve N=5");
         Check (Is_Solved (B5), "N=5 board solved");
      end;
      declare
         B6 : Board (1 .. 6);
      begin
         Params :=
           Default_Parameters
             (Max_Steps => 1_000, Seed => 8, Restarts => 5);
         Solve_N_Queens (6, Params, B6, Res);
         Check (Res.Solved, "Solve N=6");
      end;
      declare
         B10 : Board (1 .. 10);
      begin
         Params :=
           Default_Parameters
             (Max_Steps => 5_000, Seed => 2, Restarts => 15);
         Solve_N_Queens (10, Params, B10, Res);
         Check (Res.Solved, "Solve N=10");
         Check (Conflict_Count (B10) = 0, "N=10 Conflict_Count=0");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("12. Restarts accumulate");
   ---------------------------------------------------------------------
   declare
      B      : Board (1 .. 8);
      Params : Parameters;
      Res    : Solve_Result;
   begin
      --  Very tight Max_Steps forces restarts on N=8.
      Params :=
        Default_Parameters (Max_Steps => 1, Seed => 99, Restarts => 40);
      Solve_N_Queens (8, Params, B, Res);
      Check (Res.Solved or else Res.Restarts_Used > 0,
             "tight budget uses restarts or luckily solves");
      Check (Res.Restarts_Used <= 40, "Restarts_Used within cap");
   end;

   ---------------------------------------------------------------------
   Section ("13. Map coloring sketch");
   ---------------------------------------------------------------------
   declare
      CSP    : Map_CSP;
      Colors : Color_Assignment (1 .. 4);
      Params : Parameters;
      Res    : Solve_Result;
      Bad    : constant Color_Assignment (1 .. 4) := [1, 1, 1, 1];
   begin
      Build_Four_Region_Map (CSP);
      Check (CSP.Num_Regions = 4, "map 4 regions");
      Check (CSP.Num_Colors = 3, "map 3 colors");
      Check (CSP.Num_Edges = 5, "map 5 edges");

      Check (Map_Conflict_Count (CSP, Bad) = 5, "all-same-color 5 conflicts");
      Check (not Map_Is_Solved (CSP, Bad), "all-same not solved");
      Check (Map_Variable_Conflicts (CSP, Bad, 1) = 3,
             "region1 degree-3 when monochrome");

      --  Valid 3-coloring of C4+chord: 1=1,2=2,3=1,4=2 works? Edge 1-3
      --  both color 1 → conflict. Try 1=1,2=2,3=3,4=2:
      --  edges: 1-2 ok, 2-3 ok, 3-4 ok, 4-1 ok, 1-3 ok.
      Colors := [1, 2, 3, 2];
      Check (Map_Conflict_Count (CSP, Colors) = 0, "hand coloring solved");
      Check (Map_Is_Solved (CSP, Colors), "hand coloring Is_Solved");

      Params :=
        Default_Parameters (Max_Steps => 200, Seed => 3, Restarts => 5);
      Solve_Map_Coloring (CSP, Params, Colors, Res);
      Check (Res.Solved, "Solve_Map_Coloring succeeds");
      Check (Map_Is_Solved (CSP, Colors), "map board solved");
      Check (Res.Final_Conflicts = 0, "map Final_Conflicts=0");

      Params :=
        Default_Parameters (Max_Steps => 0, Seed => 1, Restarts => 0);
      Solve_Map_Coloring (CSP, Params, Colors, Res);
      Check (Res.Steps_Used = 0, "map Max_Steps=0 Steps=0");
   end;

   ---------------------------------------------------------------------
   Section ("14. N=16 educational cap smoke");
   ---------------------------------------------------------------------
   declare
      B      : Board (1 .. 16);
      Params : Parameters;
      Res    : Solve_Result;
   begin
      Params :=
        Default_Parameters
          (Max_Steps => 10_000, Seed => 1, Restarts => 20);
      Solve_N_Queens (16, Params, B, Res);
      Check (Res.Solved, "Solve N=16");
      Check (Is_Solved (B), "N=16 Is_Solved");
   end;

   ---------------------------------------------------------------------
   Section ("15. Conflict identity: sum vc = 2 * pairs");
   ---------------------------------------------------------------------
   declare
      B     : constant Board := [1, 3, 1, 4, 2];
      Sum   : Natural := 0;
      Pairs : Natural;
   begin
      for R in B'Range loop
         Sum := Sum + Variable_Conflicts (B, R);
      end loop;
      Pairs := Conflict_Count (B);
      Check (Sum = 2 * Pairs, "sum Variable_Conflicts = 2 * Conflict_Count");
      Check (Pairs > 0, "N=5 mixed has conflicts");
   end;

   New_Line;
   Put_Line ("======================================");
   Put_Line ("Pass_Count =" & Pass_Count'Image);
   Put_Line ("Fail_Count =" & Fail_Count'Image);
   if Fail_Count = 0 then
      Put_Line ("ALL PASSED");
   else
      Put_Line ("SOME FAILED");
   end if;
   Put_Line ("======================================");

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
