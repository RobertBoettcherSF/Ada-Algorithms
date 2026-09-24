--  Standalone test suite for Constraint_Satisfaction (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with Constraint_Satisfaction; use Constraint_Satisfaction;

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

   function Singleton (V : Value) return Domain is
      D : Domain := Empty_Domain;
   begin
      D (V) := True;
      return D;
   end Singleton;

begin
   Put_Line ("Constraint_Satisfaction test suite");
   Put_Line ("==================================");

   ---------------------------------------------------------------------
   Section ("1. Domain helpers");
   ---------------------------------------------------------------------
   declare
      E : constant Domain := Empty_Domain;
      F : constant Domain := Full_Domain (4);
      D : Domain;
   begin
      Check (Is_Empty (E), "Empty_Domain is empty");
      Check (Domain_Size (E) = 0, "Empty_Domain size 0");
      Check (Domain_Size (F) = 4, "Full_Domain(4) size 4");
      Check (Contains (F, 1) and Contains (F, 4), "Full_Domain contains 1,4");
      Check (not Contains (F, 5), "Full_Domain(4) lacks 5");
      Check (not Is_Empty (F), "Full_Domain not empty");
      Check (First_Value (E) = 0, "First_Value empty = 0");
      Check (First_Value (F) = 1, "First_Value full = 1");

      D := F;
      Remove_Value (D, 2);
      Check (Domain_Size (D) = 3, "Remove_Value shrinks");
      Check (not Contains (D, 2), "Remove_Value drops 2");
      Remove_Value (D, 1);
      Remove_Value (D, 3);
      Remove_Value (D, 4);
      Check (Is_Empty (D), "all removed => empty");
      Check (Domain_Size (Singleton (7)) = 1, "Singleton size 1");
      Check (Contains (Singleton (7), 7), "Singleton contains 7");
   end;

   ---------------------------------------------------------------------
   Section ("2. Init / constraints / Satisfies");
   ---------------------------------------------------------------------
   declare
      P : CSP;
      C : Constraint;
      M : Allowed_Matrix := [others => [others => False]];
   begin
      Init (P, 3, 4);
      Check (P.Num_Vars = 3, "Init Num_Vars=3");
      Check (P.Num_Constraints = 0, "Init no constraints");
      Check (Domain_Size (P.Domains (1)) = 4, "Init Dom(1)=4");
      Check (Domain_Size (P.Domains (2)) = 4, "Init Dom(2)=4");
      Check (Domain_Size (P.Domains (3)) = 4, "Init Dom(3)=4");

      Set_Domain (P, 2, Singleton (3));
      Check (Domain_Size (P.Domains (2)) = 1, "Set_Domain singleton");
      Check (Contains (P.Domains (2), 3), "Set_Domain value 3");

      C := (Left => 1, Right => 2, Kind => Not_Equal,
            Allowed => [others => [others => False]]);
      Check (Satisfies (C, 1, 2), "Not_Equal 1/=2");
      Check (not Satisfies (C, 5, 5), "Not_equal 5=5 false");

      M (2, 4) := True;
      C := (Left => 1, Right => 2, Kind => Allowed_Pairs, Allowed => M);
      Check (Satisfies (C, 2, 4), "Allowed_Pairs (2,4)");
      Check (not Satisfies (C, 2, 3), "Allowed_Pairs (2,3) false");

      Init (P, 3, 3);
      Add_Not_Equal (P, 1, 2);
      Add_Not_Equal (P, 2, 3);
      Check (P.Num_Constraints = 2, "two Not_Equal added");

      Init (P, 3, 3);
      Add_All_Different (P);
      Check (P.Num_Constraints = 3, "alldiff 3 vars => 3 edges");
   end;

   ---------------------------------------------------------------------
   Section ("3. Is_Consistent / Is_Complete / Is_Solution");
   ---------------------------------------------------------------------
   declare
      P : CSP;
      A : Assignment := [others => 0];
   begin
      Init (P, 3, 3);
      Add_Not_Equal (P, 1, 2);
      Add_Not_Equal (P, 2, 3);
      Add_Not_Equal (P, 1, 3);

      Check (Is_Consistent (P, A), "empty assignment consistent");
      Check (not Is_Complete (P, A), "empty not complete");
      Check (not Is_Solution (P, A), "empty not solution");

      A (1) := 1;
      A (2) := 1;
      Check (not Is_Consistent (P, A), "1=1 on edge inconsistent");
      Check (not Is_Assigned (A, 3), "var 3 unassigned");
      Check (Is_Assigned (A, 1), "var 1 assigned");

      A (2) := 2;
      Check (Is_Consistent (P, A), "partial 1,2 consistent");
      A (3) := 3;
      Check (Is_Complete (P, A), "full assignment complete");
      Check (Is_Consistent (P, A), "1,2,3 alldiff consistent");
      Check (Is_Solution (P, A), "1,2,3 is solution");

      A (3) := 1;
      Check (not Is_Consistent (P, A), "1 and 3 both 1 inconsistent");
      Check (not Is_Solution (P, A), "not a solution");
   end;

   ---------------------------------------------------------------------
   Section ("4. Backtrack_Solve / Count_Solutions");
   ---------------------------------------------------------------------
   declare
      P  : CSP;
      R  : Solve_Result;
      CR : Count_Result;
   begin
      --  2 vars, Not_equal, domain {1,2} => 2 solutions
      Init (P, 2, 2);
      Add_Not_Equal (P, 1, 2);
      Backtrack_Solve (P, R, Use_MRV => False);
      Check (R.Status = Solved, "BT 2-var solved");
      Check (Is_Solution (P, R.Solution), "BT solution valid");
      Check (R.Solution (1) /= R.Solution (2), "BT values differ");

      Count_Solutions (P, CR, Use_MRV => False);
      Check (CR.Count = 2, "BT count 2-var = 2");

      Backtrack_Solve (P, R, Use_MRV => True);
      Check (R.Status = Solved, "BT+MRV solved");
      Count_Solutions (P, CR, Use_MRV => True);
      Check (CR.Count = 2, "BT+MRV count = 2");

      --  Unsat: 3 vars, 2 colours, complete K3
      Init (P, 3, 2);
      Add_All_Different (P);
      Backtrack_Solve (P, R);
      Check (R.Status = Unsatisfiable, "K3/2colours unsat");
      Count_Solutions (P, CR);
      Check (CR.Count = 0, "K3/2colours count 0");

      --  3 vars alldiff 3 colours => 3! = 6
      Init (P, 3, 3);
      Add_All_Different (P);
      Count_Solutions (P, CR);
      Check (CR.Count = 6, "alldiff 3 count = 6");
      Backtrack_Solve (P, R, Use_MRV => True);
      Check (R.Status = Solved and then Is_Solution (P, R.Solution),
             "alldiff 3 BT+MRV solution");
   end;

   ---------------------------------------------------------------------
   Section ("5. Forward_Check_Solve");
   ---------------------------------------------------------------------
   declare
      P : CSP;
      R : Solve_Result;
   begin
      Init (P, 2, 2);
      Add_Not_Equal (P, 1, 2);
      Forward_Check_Solve (P, R);
      Check (R.Status = Solved, "FC 2-var solved");
      Check (Is_Solution (P, R.Solution), "FC solution valid");

      Forward_Check_Solve (P, R, Use_MRV => True);
      Check (R.Status = Solved, "FC+MRV solved");

      Init (P, 3, 2);
      Add_All_Different (P);
      Forward_Check_Solve (P, R);
      Check (R.Status = Unsatisfiable, "FC K3/2 unsat");

      Init (P, 3, 3);
      Add_All_Different (P);
      Forward_Check_Solve (P, R, Use_MRV => True);
      Check (R.Status = Solved and then Is_Solution (P, R.Solution),
             "FC alldiff 3 solved");

      Build_Map_Coloring (P, 4, 2);
      Forward_Check_Solve (P, R);
      Check (R.Status = Solved, "FC path-4 / 2 colours");
      Check (Is_Solution (P, R.Solution), "FC path-4 solution valid");
   end;

   ---------------------------------------------------------------------
   Section ("6. Arc consistency (Revise / AC_Filter)");
   ---------------------------------------------------------------------
   declare
      P : CSP;
      AR : AC_Result;
      Changed : Boolean;
   begin
      Init (P, 2, 3);
      Add_Not_Equal (P, 1, 2);
      Set_Domain (P, 2, Singleton (2));
      --  Dom(1)={1,2,3}, Dom(2)={2} => Revise(1,2) drops 2
      Changed := Revise (P, 1, 2);
      Check (Changed, "Revise drops unsupported");
      Check (not Contains (P.Domains (1), 2), "value 2 removed from Dom(1)");
      Check (Contains (P.Domains (1), 1), "value 1 kept");
      Check (Contains (P.Domains (1), 3), "value 3 kept");
      Check (Has_Support (P, 1, 2, 1), "1 has support vs {2}");
      Check (not Has_Support (P, 1, 2, 2), "2 has no support vs {2}");

      Build_Australia_Map (P);
      AC_Filter (P, AR);
      Check (AR.Status = Success, "Australia AC_Filter success");
      for V in Variable_Id range 1 .. 7 loop
         Check (Domain_Size (P.Domains (V)) = 3,
                "Australia Dom stays size 3 after weak AC");
      end loop;

      --  Unsat triangle: 3 vars, 2 colours, K3
      Init (P, 3, 2);
      Add_All_Different (P);
      --  Weak one-pass AC may not wipe out; pin one domain to force prune chain
      Set_Domain (P, 1, Singleton (1));
      AC_Filter (P, AR);
      --  After pinning X1=1, neighbours lose 1; may still be Success (2 left)
      Check (not Contains (P.Domains (2), 1),
             "AC_Filter prunes colour 1 from neighbour");
      Check (Is_Empty (P.Domains (2)) or else Domain_Size (P.Domains (2)) = 1,
             "AC_Filter neighbour wiped or singleton");

      Init (P, 2, 1);
      Add_Not_Equal (P, 1, 2);
      AC_Filter (P, AR);
      Check (AR.Status = Domain_Wipeout, "Dom={1} Not_equal wipeout");
   end;

   ---------------------------------------------------------------------
   Section ("7. Map colouring demos");
   ---------------------------------------------------------------------
   declare
      P  : CSP;
      R  : Solve_Result;
      CR : Count_Result;
   begin
      Build_Map_Coloring (P, 3, 2);
      Check (P.Num_Vars = 3, "path map 3 regions");
      Check (P.Num_Constraints = 2, "path map 2 edges");
      Backtrack_Solve (P, R);
      Check (R.Status = Solved, "path-3 / 2 colours solved");
      Count_Solutions (P, CR);
      --  Path of 3 with 2 colours: only (1,2,1) and (2,1,2)
      Check (CR.Count = 2, "path-3 / 2 colours count=2");

      Build_Australia_Map (P);
      Check (P.Num_Vars = 7, "Australia 7 regions");
      Check (P.Num_Constraints = 9, "Australia 9 edges");
      Backtrack_Solve (P, R, Use_MRV => True);
      Check (R.Status = Solved, "Australia BT solved");
      Check (Is_Solution (P, R.Solution), "Australia solution valid");
      Forward_Check_Solve (P, R, Use_MRV => True);
      Check (R.Status = Solved, "Australia FC solved");
      Check (Is_Solution (P, R.Solution), "Australia FC solution valid");
   end;

   ---------------------------------------------------------------------
   Section ("8. N-queens (N<=5)");
   ---------------------------------------------------------------------
   declare
      P  : CSP;
      R  : Solve_Result;
      CR : Count_Result;
   begin
      Build_N_Queens (P, 1);
      Count_Solutions (P, CR);
      Check (CR.Count = 1, "queens N=1 count=1");
      Backtrack_Solve (P, R);
      Check (R.Status = Solved and then R.Solution (1) = 1, "queens N=1 sol");

      Build_N_Queens (P, 2);
      Count_Solutions (P, CR);
      Check (CR.Count = 0, "queens N=2 count=0");
      Backtrack_Solve (P, R);
      Check (R.Status = Unsatisfiable, "queens N=2 unsat");

      Build_N_Queens (P, 3);
      Count_Solutions (P, CR);
      Check (CR.Count = 0, "queens N=3 count=0");

      Build_N_Queens (P, 4);
      Check (P.Num_Vars = 4, "queens N=4 vars");
      Count_Solutions (P, CR);
      Check (CR.Count = 2, "queens N=4 count=2");
      Backtrack_Solve (P, R, Use_MRV => True);
      Check (R.Status = Solved, "queens N=4 solved");
      Check (Is_Solution (P, R.Solution), "queens N=4 solution valid");
      Forward_Check_Solve (P, R);
      Check (R.Status = Solved and then Is_Solution (P, R.Solution),
             "queens N=4 FC solved");

      Build_N_Queens (P, 5);
      Count_Solutions (P, CR, Use_MRV => True);
      Check (CR.Count = 10, "queens N=5 count=10");
      Backtrack_Solve (P, R, Use_MRV => True);
      Check (R.Status = Solved and then Is_Solution (P, R.Solution),
             "queens N=5 solved");
   end;

   ---------------------------------------------------------------------
   Section ("9. Min-conflicts step");
   ---------------------------------------------------------------------
   declare
      P : CSP;
      A : Assignment := [others => 0];
      Changed : Boolean;
      Before, After : Natural;
   begin
      Init (P, 3, 3);
      Add_Not_Equal (P, 1, 2);
      Add_Not_Equal (P, 2, 3);
      A (1) := 1;
      A (2) := 1;  -- conflict with 1
      A (3) := 1;  -- conflict with 2
      Check (Is_Complete (P, A), "MC start complete");
      Before := Conflict_Count (P, A);
      Check (Before = 2, "MC start 2 conflicts");
      Min_Conflicts_Step (P, A, 2, Changed);
      After := Conflict_Count (P, A);
      Check (Changed, "MC step changed var 2");
      Check (After < Before, "MC step reduced conflicts");
      Check (A (2) /= 1, "MC step left value 1");

      --  Already optimal: no beneficial change required
      A := [1 => 1, 2 => 2, 3 => 3, others => 0];
      Before := Conflict_Count (P, A);
      Check (Before = 0, "optimal has 0 conflicts");
      Min_Conflicts_Step (P, A, 2, Changed);
      Check (Conflict_Count (P, A) = 0, "MC on optimal stays 0");
      Check (A (2) = 2, "MC tie keeps smallest / current best");
   end;

   ---------------------------------------------------------------------
   Section ("10. Method taxonomy");
   ---------------------------------------------------------------------
   declare
      Info : Method_Info;
   begin
      Check (Implemented (Backtracking), "Backtracking implemented");
      Check (not Forthcoming (Backtracking), "Backtracking not forthcoming");
      Check (Method_Name (Backtracking) = "Backtracking", "name Backtracking");

      Check (Implemented (Forward_Checking), "FC implemented");
      Check (not Forthcoming (Forward_Checking), "FC not forthcoming");
      Check (Method_Name (Forward_Checking) = "Forward_Checking", "name FC");

      Check (Implemented (Arc_Consistency), "AC implemented");
      Check (not Forthcoming (Arc_Consistency), "AC not forthcoming");
      Check (Method_Name (Arc_Consistency) = "Arc_Consistency", "name AC");

      Check (Implemented (Min_Conflicts_Local), "MC step implemented");
      Check (Method_Name (Min_Conflicts_Local) = "Min_Conflicts_Local",
             "name MC");

      Check (not Implemented (SAT_Encoding), "SAT not implemented");
      Check (Forthcoming (SAT_Encoding), "SAT forthcoming");
      Check (Method_Name (SAT_Encoding) = "SAT_Encoding", "name SAT");

      Info := Classify (Backtracking);
      Check (Info.Implemented and then not Info.Forthcoming,
             "Classify Backtracking flags");
      Info := Classify (SAT_Encoding);
      Check (not Info.Implemented and then Info.Forthcoming,
             "Classify SAT flags");
      Info := Classify (Arc_Consistency);
      Check (Info.Kind = Arc_Consistency, "Classify Kind field");

      --  Every method has a non-empty name
      for K in Method_Kind loop
         Check (Method_Name (K)'Length > 0, "Method_Name nonempty");
         Info := Classify (K);
         Check (Info.Kind = K, "Classify Kind matches");
         Check (Implemented (K) = Info.Implemented, "Implemented agrees");
         Check (Forthcoming (K) = Info.Forthcoming, "Forthcoming agrees");
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("11. Select_Unassigned / MRV");
   ---------------------------------------------------------------------
   declare
      P : CSP;
      A : Assignment := [others => 0];
      V : Natural;
   begin
      Init (P, 3, 3);
      Add_Not_Equal (P, 1, 2);
      V := Select_Unassigned (P, A, Use_MRV => False);
      Check (V = 1, "default select first unassigned");
      A (1) := 1;
      V := Select_Unassigned (P, A, Use_MRV => False);
      Check (V = 2, "select next after assign");
      A (2) := 2;
      A (3) := 3;
      V := Select_Unassigned (P, A, Use_MRV => False);
      Check (V = 0, "none unassigned => 0");

      A := [others => 0];
      Set_Domain (P, 2, Singleton (1));
      Set_Domain (P, 3, Full_Domain (3));
      Set_Domain (P, 1, Full_Domain (3));
      V := Select_Unassigned (P, A, Use_MRV => True);
      Check (V = 2, "MRV picks singleton domain");
   end;

   ---------------------------------------------------------------------
   Section ("12. Extra consistency / edge cases");
   ---------------------------------------------------------------------
   declare
      P  : CSP;
      R  : Solve_Result;
      CR : Count_Result;
      A  : Assignment := [others => 0];
      M  : Allowed_Matrix := [others => [others => False]];
   begin
      --  Allowed_Pairs only (1,2) and (2,1)
      Init (P, 2, 2);
      M (1, 2) := True;
      M (2, 1) := True;
      Add_Allowed_Pairs (P, 1, 2, M);
      Count_Solutions (P, CR);
      Check (CR.Count = 2, "Allowed_Pairs count=2");
      A (1) := 1;
      A (2) := 1;
      Check (not Is_Consistent (P, A), "Allowed_Pairs rejects (1,1)");
      A (2) := 2;
      Check (Is_Consistent (P, A), "Allowed_Pairs accepts (1,2)");

      Build_Map_Coloring (P, 2, 1);
      Backtrack_Solve (P, R);
      Check (R.Status = Unsatisfiable, "2 regions 1 colour unsat");

      Build_Map_Coloring (P, 5, 3);
      Backtrack_Solve (P, R, Use_MRV => True);
      Check (R.Status = Solved, "path-5 / 3 colours");
      Check (Is_Solution (P, R.Solution), "path-5 solution");

      --  Capacity exercised near demos (constants documented in README)
      Init (P, Max_Vars, Max_Domain);
      Check (P.Num_Vars = Max_Vars, "Init at Max_Vars");
      Check (Domain_Size (P.Domains (1)) = Max_Domain, "Init at Max_Domain");

      --  Nodes counter moves
      Init (P, 2, 2);
      Add_Not_Equal (P, 1, 2);
      Backtrack_Solve (P, R);
      Check (R.Nodes > 0, "BT nodes > 0");
      Forward_Check_Solve (P, R);
      Check (R.Nodes > 0, "FC nodes > 0");
   end;

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   New_Line;
   Put_Line ("========================================");
   Put_Line
     ("Result: Pass_Count="
      & Natural'Image (Pass_Count)
      & " Fail_Count="
      & Natural'Image (Fail_Count));
   if Fail_Count = 0 and then Pass_Count >= 80 then
      Put_Line ("ALL PASSED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   elsif Fail_Count = 0 then
      Put_Line ("ALL PASSED (but Pass_Count < 80)");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Put_Line ("FAILURES PRESENT");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;

end Tests;
