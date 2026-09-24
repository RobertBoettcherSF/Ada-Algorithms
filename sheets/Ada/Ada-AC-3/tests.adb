--  Standalone test suite for AC_3 (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with AC_3; use AC_3;

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

   function Two_Values (A, B : Value) return Domain is
      D : Domain := Empty_Domain;
   begin
      D (A) := True;
      D (B) := True;
      return D;
   end Two_Values;

begin
   Put_Line ("AC_3 test suite");
   Put_Line ("===============");

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

      D := F;
      Remove_Value (D, 2);
      Check (Domain_Size (D) = 3, "Remove_Value shrinks");
      Check (not Contains (D, 2), "Remove_Value drops 2");
      Remove_Value (D, 1);
      Remove_Value (D, 3);
      Remove_Value (D, 4);
      Check (Is_Empty (D), "all removed => empty");

      D := Singleton (7);
      Check (Domain_Size (D) = 1 and Contains (D, 7), "Singleton(7)");
      D := Two_Values (2, 5);
      Check (Domain_Size (D) = 2, "Two_Values size 2");
   end;

   ---------------------------------------------------------------------
   Section ("2. Init / Set_Domain / Satisfies");
   ---------------------------------------------------------------------
   declare
      P : CSP;
      C : Constraint;
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
      Check (not Satisfies (C, 5, 5), "Not_Equal 5=5 false");

      C.Kind := Less_Than;
      Check (Satisfies (C, 1, 3), "Less_Than 1<3");
      Check (not Satisfies (C, 4, 2), "Less_Than 4<2 false");
      Check (not Satisfies (C, 3, 3), "Less_Than 3<3 false");

      C.Kind := Allowed_Pairs;
      C.Allowed (2, 4) := True;
      Check (Satisfies (C, 2, 4), "Allowed_Pairs (2,4)");
      Check (not Satisfies (C, 2, 3), "Allowed_Pairs (2,3) false");
   end;

   ---------------------------------------------------------------------
   Section ("3. Revise correctness");
   ---------------------------------------------------------------------
   declare
      P       : CSP;
      Changed : Boolean;
   begin
      --  X1 in {1,2,3}, X2 in {2}, Not_Equal => remove 2 from X1
      Init (P, 2, 3);
      Set_Domain (P, 2, Singleton (2));
      Add_Not_Equal (P, 1, 2);
      Changed := Revise (P, 1, 2);
      Check (Changed, "Revise Not_Equal changed");
      Check (not Contains (P.Domains (1), 2), "Revise dropped unsupported 2");
      Check (Contains (P.Domains (1), 1)
        and Contains (P.Domains (1), 3), "Revise kept 1 and 3");
      Check (Domain_Size (P.Domains (1)) = 2, "Revise Dom(1)=2");

      --  Revising X2 w.r.t X1: X2={2} still supported by 1 or 3
      Changed := Revise (P, 2, 1);
      Check (not Changed, "Revise X2 no change");
      Check (Contains (P.Domains (2), 2), "Dom(2) still {2}");
   end;

   declare
      P       : CSP;
      Changed : Boolean;
   begin
      --  Less_Than: X1 < X2; Dom(X1)={1,2,3}, Dom(X2)={2}
      --  Support: 1<2 ok, 2<2 no, 3<2 no => Dom(X1) becomes {1}
      Init (P, 2, 3);
      Set_Domain (P, 2, Singleton (2));
      Add_Less_Than (P, 1, 2);
      Changed := Revise (P, 1, 2);
      Check (Changed, "Revise Less_Than changed");
      Check (Domain_Size (P.Domains (1)) = 1, "Less_Than Dom(1)=1");
      Check (Contains (P.Domains (1), 1), "Less_Than kept 1");
   end;

   declare
      P       : CSP;
      Changed : Boolean;
      Allowed : Allowed_Matrix := [others => [others => False]];
   begin
      --  Allowed only (1,1) and (2,3); Dom both full {1,2,3}
      Allowed (1, 1) := True;
      Allowed (2, 3) := True;
      Init (P, 2, 3);
      Add_Allowed_Pairs (P, 1, 2, Allowed);
      Changed := Revise (P, 1, 2);
      Check (Changed, "Revise Allowed changed X1");
      Check (Contains (P.Domains (1), 1)
        and Contains (P.Domains (1), 2), "Allowed kept 1,2 in X1");
      Check (not Contains (P.Domains (1), 3), "Allowed dropped 3 from X1");
      Changed := Revise (P, 2, 1);
      Check (Changed, "Revise Allowed changed X2");
      Check (Contains (P.Domains (2), 1)
        and Contains (P.Domains (2), 3), "Allowed kept 1,3 in X2");
      Check (not Contains (P.Domains (2), 2), "Allowed dropped 2 from X2");
   end;

   declare
      P       : CSP;
      Changed : Boolean;
   begin
      --  No support at all => wipeout on Xi
      Init (P, 2, 2);
      Set_Domain (P, 1, Singleton (1));
      Set_Domain (P, 2, Singleton (1));
      Add_Not_Equal (P, 1, 2);
      Changed := Revise (P, 1, 2);
      Check (Changed, "Revise wipeout changed");
      Check (Is_Empty (P.Domains (1)), "Revise wipeout Dom(1) empty");
   end;

   ---------------------------------------------------------------------
   Section ("4. AC-3 / Make_Arc_Consistent — simple");
   ---------------------------------------------------------------------
   declare
      P : CSP;
      R : AC3_Result;
   begin
      --  Wikipedia-ish: X even + X+Y=4 is unary+binary; we encode binary
      --  X+Y=4 as Allowed pairs with Dom(X)={0..} skipped (1-based).
      --  Use X in {1,2,3,4}, Y in {1,2,3,4}, X+Y=5 Allowed.
      declare
         Allowed : Allowed_Matrix := [others => [others => False]];
      begin
         for Vx in 1 .. 4 loop
            for Vy in 1 .. 4 loop
               if Vx + Vy = 5 then
                  Allowed (Vx, Vy) := True;
               end if;
            end loop;
         end loop;
         Init (P, 2, 4);
         Add_Allowed_Pairs (P, 1, 2, Allowed);
         AC3 (P, R);
         Check (R.Status = Success, "sum=5 AC3 Success");
         Check (Domain_Size (P.Domains (1)) = 4, "sum=5 Dom(X) all ok");
         Check (Domain_Size (P.Domains (2)) = 4, "sum=5 Dom(Y) all ok");
         --  Restrict X to {1,2} => Y must be {4,3}
         Set_Domain (P, 1, Two_Values (1, 2));
         Make_Arc_Consistent (P, R);
         Check (R.Status = Success, "sum=5 restricted Success");
         Check (Contains (P.Domains (2), 3)
           and Contains (P.Domains (2), 4), "Y pruned to {3,4}");
         Check (not Contains (P.Domains (2), 1)
           and not Contains (P.Domains (2), 2), "Y lost 1,2");
      end;
   end;

   declare
      P : CSP;
      R : AC3_Result;
   begin
      Init (P, 2, 3);
      Add_Less_Than (P, 1, 2);
      AC3 (P, R);
      Check (R.Status = Success, "X<Y AC3 Success");
      --  X cannot be 3 (no larger Y); Y cannot be 1 (no smaller X)
      Check (not Contains (P.Domains (1), 3), "X<Y removed X=3");
      Check (not Contains (P.Domains (2), 1), "X<Y removed Y=1");
      Check (Contains (P.Domains (1), 1)
        and Contains (P.Domains (1), 2), "X keeps 1,2");
      Check (Contains (P.Domains (2), 2)
        and Contains (P.Domains (2), 3), "Y keeps 2,3");
   end;

   ---------------------------------------------------------------------
   Section ("5. Australia map colouring");
   ---------------------------------------------------------------------
   declare
      P : CSP;
      R : AC3_Result;
      All_Three : Boolean := True;
   begin
      Build_Australia_Map (P);
      Check (P.Num_Vars = 7, "Aus Num_Vars=7");
      Check (P.Num_Constraints = 9, "Aus 9 borders");
      for V in 1 .. 7 loop
         if Domain_Size (P.Domains (V)) /= 3 then
            All_Three := False;
         end if;
      end loop;
      Check (All_Three, "Aus all Dom size 3 before AC3");

      AC3 (P, R);
      Check (R.Status = Success, "Aus AC3 Success");
      --  With 3 colours and this map, AC-3 alone does not wipe domains;
      --  SA (var 3) is most constrained but still size 3 under pure AC.
      Check (Domain_Size (P.Domains (3)) = 3, "Aus SA still size 3");
      Check (Domain_Size (P.Domains (7)) = 3, "Aus Tasmania untouched");

      --  Fix WA=1, NT=2 => SA cannot be 1 or 2 after AC3
      Build_Australia_Map (P);
      Set_Domain (P, 1, Singleton (1)); -- WA
      Set_Domain (P, 2, Singleton (2)); -- NT
      AC3 (P, R);
      Check (R.Status = Success, "Aus partial Success");
      Check (Domain_Size (P.Domains (1)) = 1, "WA fixed");
      Check (Domain_Size (P.Domains (2)) = 1, "NT fixed");
      Check (Contains (P.Domains (3), 3)
        and not Contains (P.Domains (3), 1)
        and not Contains (P.Domains (3), 2), "SA forced to colour 3");
   end;

   ---------------------------------------------------------------------
   Section ("6. Unsat triangle wipeout");
   ---------------------------------------------------------------------
   declare
      P : CSP;
      R : AC3_Result;
   begin
      Build_Unsat_Triangle (P);
      Check (P.Num_Vars = 3, "triangle 3 vars");
      Check (P.Num_Constraints = 3, "triangle 3 edges");
      AC3 (P, R);
      --  K3 with 2 colours is not arc-consistent: AC-3 alone may NOT wipe
      --  domains (each pair still has support). Force a partial assignment.
      Check (R.Status = Success, "bare triangle still AC (domains size 2)");

      --  Fix X1=1 => X2,X3 become {2}; then X2!=X3 wipeout
      Build_Unsat_Triangle (P);
      Set_Domain (P, 1, Singleton (1));
      AC3 (P, R);
      Check (R.Status = Domain_Wipeout, "triangle+fix => wipeout");
   end;

   declare
      P : CSP;
      R : AC3_Result;
   begin
      --  Direct wipeout: 2 vars, Dom={1}, Not_Equal
      Init (P, 2, 1);
      Add_Not_Equal (P, 1, 2);
      AC3 (P, R);
      Check (R.Status = Domain_Wipeout, "singleton != wipeout");
   end;

   ---------------------------------------------------------------------
   Section ("7. Alldiff network");
   ---------------------------------------------------------------------
   declare
      P : CSP;
      R : AC3_Result;
   begin
      Build_Alldiff_Demo (P, N => 3, Dmax => 3);
      Check (P.Num_Constraints = 3, "alldiff-3 has C(3,2)=3");
      AC3 (P, R);
      Check (R.Status = Success, "alldiff 3/3 Success");
      Check (Domain_Size (P.Domains (1)) = 3, "alldiff no prune when |D|=N");

      --  Fix one variable => others lose that value
      Set_Domain (P, 1, Singleton (2));
      AC3 (P, R);
      Check (R.Status = Success, "alldiff after fix Success");
      Check (not Contains (P.Domains (2), 2), "alldiff X2 lost 2");
      Check (not Contains (P.Domains (3), 2), "alldiff X3 lost 2");
      Check (Domain_Size (P.Domains (2)) = 2, "alldiff X2 size 2");
      Check (Domain_Size (P.Domains (3)) = 2, "alldiff X3 size 2");
   end;

   declare
      P : CSP;
      R : AC3_Result;
   begin
      --  3 vars, domain size 2, alldiff => unsatsifiable; after fixing
      --  two distinct values, third wipes
      Build_Alldiff_Demo (P, N => 3, Dmax => 2);
      Set_Domain (P, 1, Singleton (1));
      Set_Domain (P, 2, Singleton (2));
      AC3 (P, R);
      Check (R.Status = Domain_Wipeout, "alldiff 3>2 wipeout");
   end;

   declare
      P : CSP;
      R : AC3_Result;
   begin
      Init (P, 4, 4);
      Add_All_Different (P);
      Check (P.Num_Constraints = 6, "alldiff-4 C(4,2)=6");
      AC3 (P, R);
      Check (R.Status = Success, "alldiff-4 Success");
   end;

   ---------------------------------------------------------------------
   Section ("8. N-queens binary pruning");
   ---------------------------------------------------------------------
   declare
      P : CSP;
      R : AC3_Result;
   begin
      Build_N_Queens_Binary (P, 4);
      Check (P.Num_Vars = 4, "NQ4 vars");
      Check (P.Num_Constraints = 6, "NQ4 C(4,2)=6");
      AC3 (P, R);
      Check (R.Status = Success, "NQ4 AC3 Success");
      --  Pure AC-3 on N=4 does not reduce below 4 without assignments
      Check (Domain_Size (P.Domains (1)) = 4, "NQ4 row1 still 4");

      --  Place queen row1 col2 => prune attacks
      Build_N_Queens_Binary (P, 4);
      Set_Domain (P, 1, Singleton (2));
      AC3 (P, R);
      Check (R.Status = Success, "NQ4 partial Success");
      Check (Domain_Size (P.Domains (1)) = 1, "NQ4 row1 fixed");
      --  Row 2 cannot be col2 (same col) or col1/col3 (diagonal)
      Check (not Contains (P.Domains (2), 2), "NQ4 r2 no col2");
      Check (not Contains (P.Domains (2), 1), "NQ4 r2 no col1 diag");
      Check (not Contains (P.Domains (2), 3), "NQ4 r2 no col3 diag");
      Check (Contains (P.Domains (2), 4), "NQ4 r2 keeps col4");
   end;

   declare
      P : CSP;
      R : AC3_Result;
   begin
      Build_N_Queens_Binary (P, 2);
      --  N=2: rows attack each other for every pair of columns
      AC3 (P, R);
      Check (R.Status = Domain_Wipeout, "NQ2 wipeout (no solution)");
   end;

   declare
      P : CSP;
      R : AC3_Result;
   begin
      Build_N_Queens_Binary (P, 3);
      AC3 (P, R);
      --  N=3 has no solution; AC-3 may or may not wipe without search.
      --  Force first row and expect wipeout after enough pruning.
      Build_N_Queens_Binary (P, 3);
      Set_Domain (P, 1, Singleton (1));
      AC3 (P, R);
      Check (R.Status = Domain_Wipeout
        or else Domain_Size (P.Domains (2)) < 3,
        "NQ3 partial prunes or wipeout");
      --  Stronger: try all first-row placements; each leads to wipeout
      --  or empty after AC when we also fix inconsistently — check wipeout
      --  path with two placements known bad.
      Build_N_Queens_Binary (P, 3);
      Set_Domain (P, 1, Singleton (2));
      Set_Domain (P, 2, Singleton (1));
      AC3 (P, R);
      Check (R.Status = Domain_Wipeout, "NQ3 bad partial wipeout");
   end;

   ---------------------------------------------------------------------
   Section ("9. Fill_Initial_Queue / counters");
   ---------------------------------------------------------------------
   declare
      P     : CSP;
      Q     : Arc_Queue;
      Count : Arc_Count;
      R     : AC3_Result;
   begin
      Init (P, 3, 3);
      Add_Not_Equal (P, 1, 2);
      Add_Not_Equal (P, 2, 3);
      Fill_Initial_Queue (P, Q, Count);
      Check (Count = 4, "queue has 2*2 arcs");
      Check (Q (1).Xi = 1 and Q (1).Xj = 2, "first arc (1,2)");
      Check (Q (2).Xi = 2 and Q (2).Xj = 1, "second arc (2,1)");

      AC3 (P, R);
      Check (R.Status = Success, "path-3 Success");
      Check (R.Arcs_Processed >= 4, "processed >= initial arcs");
   end;

   ---------------------------------------------------------------------
   Section ("10. Has_Support / edge cases");
   ---------------------------------------------------------------------
   declare
      P : CSP;
   begin
      Init (P, 2, 3);
      Add_Not_Equal (P, 1, 2);
      Check (Has_Support (P, 1, 2, 1), "support for 1 vs full Dom");
      Set_Domain (P, 2, Singleton (1));
      Check (not Has_Support (P, 1, 2, 1), "no support when only equal");
      Check (Has_Support (P, 1, 2, 2), "support for 2 vs {1}");
   end;

   declare
      P : CSP;
      R : AC3_Result;
   begin
      --  Single variable, no constraints — AC3 trivial success
      Init (P, 1, 5);
      AC3 (P, R);
      Check (R.Status = Success, "unary CSP Success");
      Check (Domain_Size (P.Domains (1)) = 5, "unary Dom unchanged");
      Check (R.Arcs_Processed = 0, "unary no arcs");
   end;

   declare
      P : CSP;
      R : AC3_Result;
   begin
      Init (P, 2, 4);
      Add_Less_Than (P, 1, 2);
      Add_Less_Than (P, 2, 1); -- X1<X2 and X2<X1 => wipeout
      AC3 (P, R);
      Check (R.Status = Domain_Wipeout, "contradictory < wipeout");
   end;

   ---------------------------------------------------------------------
   Section ("11. Capacity / Add_All_Different counts");
   ---------------------------------------------------------------------
   declare
      P : CSP;
      R : AC3_Result;
   begin
      Build_Alldiff_Demo (P, N => 5, Dmax => 5);
      Check (P.Num_Constraints = 10, "alldiff-5 C(5,2)=10");
      AC3 (P, R);
      Check (R.Status = Success, "alldiff-5 Success");

      Build_Australia_Map (P);
      Set_Domain (P, 1, Singleton (1));
      Set_Domain (P, 2, Singleton (1)); -- WA=NT same colour, adjacent
      AC3 (P, R);
      Check (R.Status = Domain_Wipeout, "Aus WA=NT=1 wipeout");
   end;

   ---------------------------------------------------------------------
   Section ("12. Make_Arc_Consistent alias");
   ---------------------------------------------------------------------
   declare
      P1, P2 : CSP;
      R1, R2 : AC3_Result;
   begin
      Init (P1, 2, 3);
      Add_Less_Than (P1, 1, 2);
      P2 := P1;
      AC3 (P1, R1);
      Make_Arc_Consistent (P2, R2);
      Check (R1.Status = R2.Status, "alias same status");
      Check (Domain_Size (P1.Domains (1)) = Domain_Size (P2.Domains (1)),
        "alias same Dom(1)");
      Check (Domain_Size (P1.Domains (2)) = Domain_Size (P2.Domains (2)),
        "alias same Dom(2)");
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
