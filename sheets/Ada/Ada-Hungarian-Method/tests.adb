--  Standalone test suite for Hungarian_Method (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Hungarian_Method; use Hungarian_Method;

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
         Ada.Text_IO.Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Ada.Text_IO.Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      Ada.Text_IO.New_Line;
      Ada.Text_IO.Put_Line ("=== " & Title & " ===");
   end Section;

   function Mapping_Equals
     (A : Assignment; Expected : Assignment; N : Dimension) return Boolean
   is
   begin
      for I in 1 .. N loop
         if A (I) /= Expected (I) then
            return False;
         end if;
      end loop;
      return True;
   end Mapping_Equals;

   type Bool3 is array (1 .. 3) of Boolean;
   type Bool4 is array (1 .. 4) of Boolean;
   type Bool5 is array (1 .. 5) of Boolean;
   type BoolN is array (1 .. Max_N) of Boolean;

begin
   Ada.Text_IO.Put_Line ("Hungarian_Method test suite");
   Ada.Text_IO.Put_Line ("===========================");

   ---------------------------------------------------------------------
   Section ("1. Helpers: square / pad / negate / permutation");
   ---------------------------------------------------------------------
   declare
      Sq : constant Cost_Matrix (1 .. 2, 1 .. 2) :=
        [[1, 2],
         [3, 4]];
      Rec : constant Cost_Matrix (1 .. 2, 1 .. 3) :=
        [[1, 2, 3],
         [4, 5, 6]];
      P : constant Cost_Matrix := Pad_To_Square (Rec, Fill => 0);
      N : constant Cost_Matrix := Negate (Sq);
      Id : constant Assignment (1 .. 3) := [1, 2, 3];
      Bad : constant Assignment (1 .. 3) := [1, 1, 2];
   begin
      Check (Is_Square (Sq), "Is_Square 2x2");
      Check (not Is_Square (Rec), "Is_Square rejects 2x3");
      Check (P'Length (1) = 3 and then P'Length (2) = 3, "Pad size 3");
      Check (P (1, 1) = 1 and then P (2, 3) = 6, "Pad preserves");
      Check (P (3, 1) = 0 and then P (3, 3) = 0, "Pad fill zeros");
      Check (N (1, 1) = -1 and then N (2, 2) = -4, "Negate");
      Check (Is_Permutation (Id, 3), "Is_Permutation id");
      Check (not Is_Permutation (Bad, 3), "Is_Permutation rejects");
      Check (Is_Permutation (Id, 0), "Is_Permutation N=0");
   end;

   ---------------------------------------------------------------------
   Section ("2. Empty and 1x1");
   ---------------------------------------------------------------------
   declare
      Empty : Cost_Matrix (1 .. 0, 1 .. 0);
      R0    : constant Result := Minimize_Assignment (Empty);
      One   : constant Cost_Matrix (1 .. 1, 1 .. 1) := [[42]];
      R1    : constant Result := Minimize_Assignment (One);
      R1m   : constant Result := Maximize_Assignment (One);
   begin
      Check (R0.Success and then R0.N = 0 and then R0.Total = 0,
             "empty minimize");
      Check (R1.Success and then R1.Total = 42 and then R1.Mapping (1) = 1,
             "1x1 minimize");
      Check (R1m.Success and then R1m.Total = 42 and then R1m.Mapping (1) = 1,
             "1x1 maximize");
      Check (Assignment_Cost (One, R1.Mapping (1 .. 1)) = 42,
             "Assignment_Cost 1x1");
   end;

   ---------------------------------------------------------------------
   Section ("3. Identity / diagonal costs");
   ---------------------------------------------------------------------
   declare
      --  Zero diagonal is uniquely optimal for minimization.
      C : constant Cost_Matrix (1 .. 4, 1 .. 4) :=
        [[0, 9, 9, 9],
         [9, 0, 9, 9],
         [9, 9, 0, 9],
         [9, 9, 9, 0]];
      R : constant Result := Minimize_Assignment (C);
      Exp : constant Assignment (1 .. 4) := [1, 2, 3, 4];
   begin
      Check (R.Success, "diag Success");
      Check (R.Total = 0, "diag Total 0");
      Check (Is_Permutation (R.Mapping, 4), "diag permutation");
      Check (Mapping_Equals (R.Mapping, Exp, 4), "diag identity map");
      Check (Assignment_Cost (C, R.Mapping (1 .. 4)) = 0,
             "diag Assignment_Cost");
   end;

   ---------------------------------------------------------------------
   Section ("4. Wikipedia Alice/Bob/Carol 3x3 (min cost 15)");
   ---------------------------------------------------------------------
   --  Wikipedia table (Alice / Bob / Carol):
   --    Clean bathroom | Sweep floors | Wash windows
   --    Alice   8   4   7
   --    Bob     5   2   3
   --    Carol   9   4   8
   --  Optimal: Alice-bath, Carol-sweep, Bob-windows ⇒ 8+4+3 = 15
   declare
      C : constant Cost_Matrix (1 .. 3, 1 .. 3) :=
        [[8, 4, 7],
         [5, 2, 3],
         [9, 4, 8]];
      R : constant Result := Minimize_Assignment (C);
   begin
      Check (R.Success, "wiki3 Success");
      Check (R.Total = 15, "wiki3 Total 15");
      Check (Is_Permutation (R.Mapping, 3), "wiki3 permutation");
      Check (Assignment_Cost (C, R.Mapping (1 .. 3)) = 15,
             "wiki3 Assignment_Cost");
      Check (R.Mapping (1) = 1 and then R.Mapping (2) = 3
             and then R.Mapping (3) = 2,
             "wiki3 Alice-bath Carol-sweep Bob-win");
   end;

   ---------------------------------------------------------------------
   Section ("5. Classic 4x4 textbook");
   ---------------------------------------------------------------------
   --  Common Munkres demo (min cost 76):
   --    90  75  75  80
   --    35  85  55  65
   --    125 95  90 105
   --    45  110 95 115
   --  Optimal assignment cost 75+35+90+45? Wait let's verify by brute.
   declare
      C : constant Cost_Matrix (1 .. 4, 1 .. 4) :=
        [[90,  75,  75,  80],
         [35,  85,  55,  65],
         [125, 95,  90, 105],
         [45, 110,  95, 115]];
      R : constant Result := Minimize_Assignment (C);
      --  Known optimum: row1→col2 (75), row2→col4 (65)? Actually
      --  standard answer is 75+35+90+45? columns must be unique.
      --  Optimal: (1→2:75), (2→1:35), (3→3:90), (4→? 4 is left:115)
      --           = 75+35+90+115 = 315 — wrong.
      --  Better known: 1→2(75), 2→4(65), 3→3(90), 4→1(45) = 275
      --  Or: 1→3(75), 2→1(35), 3→2(95), 4→4 — no.
      --  We'll trust the algorithm and verify via exhaustive check.
      Best : Cost := Large_Cost;

      procedure Recurse
        (Row : Positive; Used : in out Bool4; Acc : Cost)
      is
      begin
         if Row > 4 then
            if Acc < Best then
               Best := Acc;
            end if;
            return;
         end if;
         for Col in 1 .. 4 loop
            if not Used (Col) then
               Used (Col) := True;
               Recurse (Row + 1, Used, Acc + C (Row, Col));
               Used (Col) := False;
            end if;
         end loop;
      end Recurse;

      Used0 : Bool4 := [others => False];
   begin
      Recurse (1, Used0, 0);
      Check (R.Success, "4x4 Success");
      Check (Is_Permutation (R.Mapping, 4), "4x4 permutation");
      Check (R.Total = Best, "4x4 matches brute force");
      Check (Assignment_Cost (C, R.Mapping (1 .. 4)) = Best,
             "4x4 Assignment_Cost");
      Check (Best = 275, "4x4 known optimum 275");
      Check (R.Mapping (1) = 2 or else R.Mapping (1) = 3,
             "4x4 row1 picks 75-col");
   end;

   ---------------------------------------------------------------------
   Section ("6. Permutation uniqueness (strict diagonal)");
   ---------------------------------------------------------------------
   declare
      C : constant Cost_Matrix (1 .. 3, 1 .. 3) :=
        [[0, 100, 100],
         [100, 0, 100],
         [100, 100, 0]];
      R : constant Result := Minimize_Assignment (C);
   begin
      Check (R.Total = 0, "unique Total 0");
      Check (R.Mapping (1) = 1 and then R.Mapping (2) = 2
             and then R.Mapping (3) = 3,
             "unique identity only");
   end;

   ---------------------------------------------------------------------
   Section ("7. Maximize via negate");
   ---------------------------------------------------------------------
   declare
      C : constant Cost_Matrix (1 .. 3, 1 .. 3) :=
        [[1, 2, 3],
         [3, 3, 3],
         [3, 2, 1]];
      Rmax : constant Result := Maximize_Assignment (C);
      Rmin : constant Result := Minimize_Assignment (C);
      --  Max: pick large entries with unique cols.
      --  Brute max:
      Best_Max : Cost := Cost'First;
      Best_Min : Cost := Large_Cost;

      procedure Recurse
        (Row : Positive; Used : in out Bool3; Acc : Cost)
      is
      begin
         if Row > 3 then
            if Acc > Best_Max then
               Best_Max := Acc;
            end if;
            if Acc < Best_Min then
               Best_Min := Acc;
            end if;
            return;
         end if;
         for Col in 1 .. 3 loop
            if not Used (Col) then
               Used (Col) := True;
               Recurse (Row + 1, Used, Acc + C (Row, Col));
               Used (Col) := False;
            end if;
         end loop;
      end Recurse;

      Used0 : Bool3 := [others => False];
   begin
      Recurse (1, Used0, 0);
      Check (Rmax.Success and then Rmin.Success, "max/min Success");
      Check (Rmax.Total = Best_Max, "maximize matches brute");
      Check (Rmin.Total = Best_Min, "minimize matches brute");
      Check (Is_Permutation (Rmax.Mapping, 3), "max permutation");
      Check (Assignment_Cost (C, Rmax.Mapping (1 .. 3)) = Best_Max,
             "max Assignment_Cost");
   end;

   ---------------------------------------------------------------------
   Section ("8. Anti-diagonal / reverse permutation");
   ---------------------------------------------------------------------
   declare
      C : constant Cost_Matrix (1 .. 4, 1 .. 4) :=
        [[9, 9, 9, 0],
         [9, 9, 0, 9],
         [9, 0, 9, 9],
         [0, 9, 9, 9]];
      R : constant Result := Minimize_Assignment (C);
   begin
      Check (R.Total = 0, "anti-diag Total 0");
      Check (R.Mapping (1) = 4 and then R.Mapping (2) = 3
             and then R.Mapping (3) = 2 and then R.Mapping (4) = 1,
             "anti-diag reverse map");
   end;

   ---------------------------------------------------------------------
   Section ("9. Rectangular pad then solve");
   ---------------------------------------------------------------------
   declare
      Rec : constant Cost_Matrix (1 .. 2, 1 .. 3) :=
        [[4, 1, 3],
         [2, 0, 5]];
      P : constant Cost_Matrix := Pad_To_Square (Rec, Fill => 0);
      R : constant Result := Minimize_Assignment (P);
   begin
      Check (P'Length (1) = 3, "rect pad to 3");
      Check (R.Success, "rect padded Success");
      --  Padded [[4,1,3],[2,0,5],[0,0,0]]; optimum is 3
      --  (e.g. row1→col2, row2→col1, row3→col3 ⇒ 1+2+0).
      Check (R.Total = 3, "rect total 3");
      Check (Is_Permutation (R.Mapping, 3), "rect permutation");
   end;

   ---------------------------------------------------------------------
   Section ("10. Random small exhaustive (n=2,3,4)");
   ---------------------------------------------------------------------
   declare
      procedure Brute_Min
        (C : Cost_Matrix; N : Positive; Best : in out Cost)
      is
         Used : BoolN := [others => False];

         procedure Go (Row : Positive; Acc : Cost) is
         begin
            if Row > N then
               if Acc < Best then
                  Best := Acc;
               end if;
               return;
            end if;
            for Col in 1 .. N loop
               if not Used (Col) then
                  Used (Col) := True;
                  Go (Row + 1, Acc + C (Row, Col));
                  Used (Col) := False;
               end if;
            end loop;
         end Go;
      begin
         Best := Large_Cost;
         Go (1, 0);
      end Brute_Min;

      Seeds : constant array (1 .. 6) of Cost_Matrix (1 .. 3, 1 .. 3) :=
        [[[1, 2, 3], [4, 5, 6], [7, 8, 9]],
         [[9, 8, 7], [6, 5, 4], [3, 2, 1]],
         [[5, 5, 5], [5, 5, 5], [5, 5, 5]],
         [[0, 1, 2], [1, 0, 1], [2, 1, 0]],
         [[10, 1, 10], [10, 10, 1], [1, 10, 10]],
         [[2, 9, 4], [7, 1, 3], [6, 8, 5]]];
   begin
      for S in Seeds'Range loop
         declare
            Best : Cost := Large_Cost;
            R    : constant Result := Minimize_Assignment (Seeds (S));
         begin
            Brute_Min (Seeds (S), 3, Best);
            Check (R.Total = Best,
                   "seed" & Integer'Image (S) & " = brute");
            Check (Is_Permutation (R.Mapping, 3),
                   "seed" & Integer'Image (S) & " perm");
         end;
      end loop;

      --  Two 2x2
      declare
         A : constant Cost_Matrix (1 .. 2, 1 .. 2) := [[1, 2], [3, 4]];
         B : constant Cost_Matrix (1 .. 2, 1 .. 2) := [[4, 1], [2, 3]];
         RA : constant Result := Minimize_Assignment (A);
         RB : constant Result := Minimize_Assignment (B);
      begin
         Check (RA.Total = 5, "2x2 A total 1+4=5");
         Check (RB.Total = 3, "2x2 B total 1+2=3");
         Check (RA.Mapping (1) = 1 and then RA.Mapping (2) = 2,
                "2x2 A map");
         Check (RB.Mapping (1) = 2 and then RB.Mapping (2) = 1,
                "2x2 B map");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("11. Negatives and mixed signs");
   ---------------------------------------------------------------------
   declare
      C : constant Cost_Matrix (1 .. 3, 1 .. 3) :=
        [[-5,  1,  2],
         [ 3, -4,  0],
         [ 1,  2, -3]];
      R : constant Result := Minimize_Assignment (C);
      Best : Cost := Large_Cost;
      Used : Bool3 := [others => False];

      procedure Go (Row : Positive; Acc : Cost) is
      begin
         if Row > 3 then
            if Acc < Best then
               Best := Acc;
            end if;
            return;
         end if;
         for Col in 1 .. 3 loop
            if not Used (Col) then
               Used (Col) := True;
               Go (Row + 1, Acc + C (Row, Col));
               Used (Col) := False;
            end if;
         end loop;
      end Go;
   begin
      Go (1, 0);
      Check (R.Total = Best, "negatives match brute");
      Check (R.Total = (-5) + (-4) + (-3), "negatives pick diagonal -12");
      Check (R.Mapping (1) = 1 and then R.Mapping (2) = 2
             and then R.Mapping (3) = 3,
             "negatives diagonal");
   end;

   ---------------------------------------------------------------------
   Section ("12. Maximize Wikipedia-scale + identity max");
   ---------------------------------------------------------------------
   declare
      Wiki : constant Cost_Matrix (1 .. 3, 1 .. 3) :=
        [[8, 4, 7],
         [5, 2, 3],
         [9, 4, 8]];
      Rw : constant Result := Maximize_Assignment (Wiki);
      Id : constant Cost_Matrix (1 .. 3, 1 .. 3) :=
        [[5, 0, 0],
         [0, 5, 0],
         [0, 0, 5]];
      Ri : constant Result := Maximize_Assignment (Id);
      Best : Cost := Cost'First;
      Used : Bool3 := [others => False];

      procedure Go (Row : Positive; Acc : Cost) is
      begin
         if Row > 3 then
            if Acc > Best then
               Best := Acc;
            end if;
            return;
         end if;
         for Col in 1 .. 3 loop
            if not Used (Col) then
               Used (Col) := True;
               Go (Row + 1, Acc + Wiki (Row, Col));
               Used (Col) := False;
            end if;
         end loop;
      end Go;
   begin
      Go (1, 0);
      Check (Rw.Total = Best, "wiki maximize = brute");
      Check (Ri.Total = 15, "identity max 15");
      Check (Ri.Mapping (1) = 1 and then Ri.Mapping (2) = 2
             and then Ri.Mapping (3) = 3,
             "identity max map");
   end;

   ---------------------------------------------------------------------
   Section ("13. n=5 / n=6 smoke + Assignment_Cost consistency");
   ---------------------------------------------------------------------
   declare
      C5 : Cost_Matrix (1 .. 5, 1 .. 5);
      C6 : Cost_Matrix (1 .. 6, 1 .. 6);
      R5, R6 : Result;
   begin
      for I in 1 .. 5 loop
         for J in 1 .. 5 loop
            C5 (I, J) := Cost ((I * 7 + J * 3) mod 11);
         end loop;
      end loop;
      for I in 1 .. 6 loop
         for J in 1 .. 6 loop
            C6 (I, J) := Cost ((I * 5 + J * 11) mod 13);
         end loop;
      end loop;
      R5 := Minimize_Assignment (C5);
      R6 := Minimize_Assignment (C6);
      Check (R5.Success and then Is_Permutation (R5.Mapping, 5),
             "n=5 success/perm");
      Check (R6.Success and then Is_Permutation (R6.Mapping, 6),
             "n=6 success/perm");
      Check (Assignment_Cost (C5, R5.Mapping (1 .. 5)) = R5.Total,
             "n=5 cost consistency");
      Check (Assignment_Cost (C6, R6.Mapping (1 .. 6)) = R6.Total,
             "n=6 cost consistency");

      --  Brute for n=5
      declare
         Best : Cost := Large_Cost;
         Used : Bool5 := [others => False];

         procedure Go (Row : Positive; Acc : Cost) is
         begin
            if Row > 5 then
               if Acc < Best then
                  Best := Acc;
               end if;
               return;
            end if;
            for Col in 1 .. 5 loop
               if not Used (Col) then
                  Used (Col) := True;
                  Go (Row + 1, Acc + C5 (Row, Col));
                  Used (Col) := False;
               end if;
            end loop;
         end Go;
      begin
         Go (1, 0);
         Check (R5.Total = Best, "n=5 matches brute");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("14. All-equal matrix (any permutation optimal)");
   ---------------------------------------------------------------------
   declare
      C : constant Cost_Matrix (1 .. 4, 1 .. 4) :=
        [others => [others => 7]];
      R : constant Result := Minimize_Assignment (C);
      M : constant Result := Maximize_Assignment (C);
   begin
      Check (R.Total = 28, "all-equal min 4*7");
      Check (M.Total = 28, "all-equal max 4*7");
      Check (Is_Permutation (R.Mapping, 4), "all-equal min perm");
      Check (Is_Permutation (M.Mapping, 4), "all-equal max perm");
   end;

   ---------------------------------------------------------------------
   Section ("15. Pad tall matrix (3x2) and Invalid_Argument");
   ---------------------------------------------------------------------
   declare
      Tall : constant Cost_Matrix (1 .. 3, 1 .. 2) :=
        [[1, 9],
         [9, 1],
         [5, 5]];
      P : constant Cost_Matrix := Pad_To_Square (Tall, Fill => 0);
      R : constant Result := Minimize_Assignment (P);
      Bad : constant Assignment (1 .. 2) := [1, 1];
      Raised : Boolean := False;
   begin
      Check (P'Length (1) = 3 and then P'Length (2) = 3, "tall pad 3");
      Check (R.Success, "tall padded Success");
      Check (R.Total <= 2, "tall padded cheap");
      begin
         declare
            Dummy : Cost;
         begin
            Dummy := Assignment_Cost
              (Cost_Matrix'([[1, 2], [3, 4]]), Bad);
            pragma Unreferenced (Dummy);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Assignment_Cost rejects non-perm");
   end;

   ---------------------------------------------------------------------
   Section ("16. Extra exhaustive seeds for pass budget");
   ---------------------------------------------------------------------
   declare
      function Solve_Eq (C : Cost_Matrix) return Boolean is
         R : constant Result := Minimize_Assignment (C);
         N : constant Positive := C'Length (1);
         Best : Cost := Large_Cost;
         Used : BoolN := [others => False];

         procedure Go (Row : Positive; Acc : Cost) is
         begin
            if Row > N then
               if Acc < Best then
                  Best := Acc;
               end if;
               return;
            end if;
            for Col in 1 .. N loop
               if not Used (Col) then
                  Used (Col) := True;
                  Go (Row + 1, Acc + C (Row, Col));
                  Used (Col) := False;
               end if;
            end loop;
         end Go;
      begin
         Go (1, 0);
         return R.Success and then R.Total = Best
           and then Is_Permutation (R.Mapping, Dimension (N));
      end Solve_Eq;

      S1 : constant Cost_Matrix (1 .. 2, 1 .. 2) := [[0, 1], [1, 0]];
      S2 : constant Cost_Matrix (1 .. 2, 1 .. 2) := [[3, 3], [1, 2]];
      S3 : constant Cost_Matrix (1 .. 3, 1 .. 3) :=
        [[4, 1, 3], [2, 0, 5], [3, 2, 2]];
      S4 : constant Cost_Matrix (1 .. 3, 1 .. 3) :=
        [[11, 12, 13], [14, 15, 16], [17, 18, 10]];
      S5 : constant Cost_Matrix (1 .. 4, 1 .. 4) :=
        [[1, 2, 3, 4],
         [4, 1, 2, 3],
         [3, 4, 1, 2],
         [2, 3, 4, 1]];
      S6 : constant Cost_Matrix (1 .. 4, 1 .. 4) :=
        [[100, 1, 100, 100],
         [100, 100, 1, 100],
         [100, 100, 100, 1],
         [1, 100, 100, 100]];
      S7 : constant Cost_Matrix (1 .. 3, 1 .. 3) :=
        [[0, 0, 0], [0, 0, 0], [0, 0, 0]];
      S8 : constant Cost_Matrix (1 .. 3, 1 .. 3) :=
        [[8, 7, 9], [4, 2, 6], [5, 3, 1]];
   begin
      Check (Solve_Eq (S1), "extra S1");
      Check (Solve_Eq (S2), "extra S2");
      Check (Solve_Eq (S3), "extra S3");
      Check (Solve_Eq (S4), "extra S4");
      Check (Solve_Eq (S5), "extra S5");
      Check (Solve_Eq (S6), "extra S6");
      Check (Solve_Eq (S7), "extra S7 zeros");
      Check (Solve_Eq (S8), "extra S8");
      Check (Minimize_Assignment (S6).Total = 4, "S6 cycle cost 4");
      Check (Maximize_Assignment (S1).Total = 2, "S1 max 1+1=2");
      Check (Minimize_Assignment (S1).Total = 0, "S1 min 0");
      Check (Minimize_Assignment (S5).Total = 4, "S5 min all-1s =4");
   end;

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("===========================");
   Ada.Text_IO.Put_Line
     ("Passed:" & Natural'Image (Pass_Count)
      & "  Failed:" & Natural'Image (Fail_Count));
   if Fail_Count = 0 and then Pass_Count >= 80 then
      Ada.Text_IO.Put_Line ("ALL PASSED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Ada.Text_IO.Put_Line ("SOME FAILED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
