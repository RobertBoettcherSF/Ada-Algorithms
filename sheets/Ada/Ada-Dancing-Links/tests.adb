--  Standalone test suite for Dancing_Links (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with Dancing_Links; use Dancing_Links;

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

   function Sorted_Rows (Sol : Solution) return Solution is
      R : Solution := Sol;
      Tmp : Row_Id;
   begin
      for I in 1 .. R.Length loop
         for J in I + 1 .. R.Length loop
            if R.Rows (J) < R.Rows (I) then
               Tmp := R.Rows (I);
               R.Rows (I) := R.Rows (J);
               R.Rows (J) := Tmp;
            end if;
         end loop;
      end loop;
      return R;
   end Sorted_Rows;

   function Same_Rows (A, B : Solution) return Boolean is
      SA : constant Solution := Sorted_Rows (A);
      SB : constant Solution := Sorted_Rows (B);
   begin
      if SA.Length /= SB.Length then
         return False;
      end if;
      for I in 1 .. SA.Length loop
         if SA.Rows (I) /= SB.Rows (I) then
            return False;
         end if;
      end loop;
      return True;
   end Same_Rows;

begin
   Put_Line ("Dancing_Links test suite");
   Put_Line ("========================");

   ---------------------------------------------------------------------
   Section ("1. Caps / column-count helpers");
   ---------------------------------------------------------------------
   declare
      N4, N8 : Column_Count;
      S : Solver;
   begin
      N4 := N_Queens_Column_Count (4);
      N8 := N_Queens_Column_Count (8);
      Check (N_Queens_Column_Count (1) = 4, "Queens cols N=1 = 4");
      Check (N4 = 22, "Queens cols N=4 = 22");
      Check (N8 = 46, "Queens cols N=8 = 46");
      Check (N8 = Column_Count (6 * 8 - 2), "Queens formula 6N-2");
      Check (N4 < N8, "cols grow with N");
      Clear (S);
      Check (S.Last_Node = Root_Id, "Clear leaves only Root");
      Check (S.Num_Columns = 0, "Clear Num_Columns 0");
      Check (Choose_Column (S) = Root_Id, "Clear Choose Root");
   end;

   ---------------------------------------------------------------------
   Section ("2. Empty matrix → one empty solution");
   ---------------------------------------------------------------------
   declare
      S     : Solver;
      Found : Solution;
      Ok    : Boolean;
      Arr   : Solution_Array;
      Count : Natural;
   begin
      Clear (S);
      Check (Primary_Header_Count (S) = 0, "empty primary count 0");
      Check (Choose_Column (S) = Root_Id, "empty Choose → Root");
      Check (Count_Solutions (S, 10) = 1, "empty Count_Solutions = 1");
      Solve (S, Found, Ok);
      Check (Ok, "empty Solve Success");
      Check (Found.Length = 0, "empty solution length 0");
      Clear (S);
      Solve_All (S, Arr, Count, 5);
      Check (Count = 1 and then Arr (1).Length = 0, "empty Solve_All");
   end;

   ---------------------------------------------------------------------
   Section ("3. Unsatisfiable matrices → 0 solutions");
   ---------------------------------------------------------------------
   declare
      S : Solver;
      --  One column, no 1s (0 rows with that column).
      M0 : constant Bool_Matrix (1 .. 1, 1 .. 1) := [[False]];
      --  Two columns, row covers only first.
      M1 : constant Bool_Matrix (1 .. 1, 1 .. 2) := [[True, False]];
      Found : Solution;
      Ok    : Boolean;
   begin
      Build_From_Matrix (S, M0);
      Check (Header_Size (S, 1) = 0, "unsat empty-col Size=0");
      Check (Count_Solutions (S) = 0, "unsat empty-col 0 sols");
      Build_From_Matrix (S, M1);
      Check (Header_Size (S, 1) = 1, "partial cover Size col1");
      Check (Header_Size (S, 2) = 0, "partial cover Size col2=0");
      Check (Count_Solutions (S) = 0, "partial cover 0 sols");
      Solve (S, Found, Ok);
      Check (not Ok, "partial cover Solve fails");
   end;

   ---------------------------------------------------------------------
   Section ("4. Tiny exact covers");
   ---------------------------------------------------------------------
   declare
      S : Solver;
      --  Identity 2x2 → one solution: both rows.
      Id2 : constant Bool_Matrix (1 .. 2, 1 .. 2) :=
        [[True, False], [False, True]];
      --  Single 1 → one solution.
      One : constant Bool_Matrix (1 .. 1, 1 .. 1) := [[True]];
      --  Two identical full rows → two solutions (pick either).
      Dup : constant Bool_Matrix (1 .. 2, 1 .. 1) := [[True], [True]];
      Found : Solution;
      Ok    : Boolean;
      Arr   : Solution_Array;
      Count : Natural;
   begin
      Build_From_Matrix (S, One);
      Check (Count_Solutions (S) = 1, "single-1 count");
      Build_From_Matrix (S, One);
      Solve (S, Found, Ok);
      Check (Ok and then Found.Length = 1 and then Found.Rows (1) = 1,
             "single-1 rows");

      Build_From_Matrix (S, Id2);
      Check (Header_Size (S, 1) = 1 and then Header_Size (S, 2) = 1,
             "Id2 sizes");
      Check (Count_Solutions (S) = 1, "Id2 count");
      Build_From_Matrix (S, Id2);
      Solve (S, Found, Ok);
      Check (Ok and then Found.Length = 2, "Id2 length 2");
      Check (Same_Rows (Found, (Length => 2, Rows => [1, 2, others => 0])),
             "Id2 rows {1,2}");

      Build_From_Matrix (S, Dup);
      Check (Count_Solutions (S) = 2, "dup column 2 sols");
      Build_From_Matrix (S, Dup);
      Solve_All (S, Arr, Count, 10);
      Check (Count = 2, "dup Solve_All count");
      Check (Arr (1).Length = 1 and then Arr (2).Length = 1, "dup lens");
      Check ((Arr (1).Rows (1) = 1 and then Arr (2).Rows (1) = 2)
             or else (Arr (1).Rows (1) = 2 and then Arr (2).Rows (1) = 1),
             "dup rows are 1 and 2");
   end;

   ---------------------------------------------------------------------
   Section ("5. Knuth classic example (unique solution {1,4,5})");
   ---------------------------------------------------------------------
   --  Matrix rows numbered 1..6; Wikipedia solution is rows 0,3,4 in
   --  0-based → 1,4,5 in 1-based.
   declare
      S     : Solver;
      Found : Solution;
      Ok    : Boolean;
      Arr   : Solution_Array;
      Count : Natural;
      Expect : constant Solution :=
        (Length => 3, Rows => [1, 4, 5, others => 0]);
   begin
      Check (Knuth_Example_Solution_Count = 1, "Knuth count helper = 1");
      Build_Knuth_Example (S);
      Check (S.Num_Columns = 7, "Knuth 7 columns");
      Check (S.Num_Rows = 6, "Knuth 6 rows");
      Check (S.Num_Primary = 7, "Knuth all primary");
      Check (Primary_Header_Count (S) = 7, "Knuth linked 7");
      Check (Count_Solutions (S) = 1, "Knuth Count_Solutions");
      Build_Knuth_Example (S);
      Solve (S, Found, Ok);
      Check (Ok, "Knuth Solve ok");
      Check (Same_Rows (Found, Expect), "Knuth solution {1,4,5}");
      Build_Knuth_Example (S);
      Solve_All (S, Arr, Count, 10);
      Check (Count = 1 and then Same_Rows (Arr (1), Expect),
             "Knuth Solve_All");
   end;

   ---------------------------------------------------------------------
   Section ("6. Cover / Uncover restores structure");
   ---------------------------------------------------------------------
   declare
      S : Solver;
      Fp0, Fp1, Fp2 : Natural;
      C : Node_Id;
      Sz : Natural;
   begin
      Build_Knuth_Example (S);
      Fp0 := Structure_Fingerprint (S);
      C := Choose_Column (S);
      Check (C /= Root_Id, "Choose non-root on Knuth");
      Sz := Header_Size (S, C);
      Check (Sz >= 1, "chosen column Size ≥ 1");
      Cover (S, C);
      Fp1 := Structure_Fingerprint (S);
      Check (Fp1 /= Fp0, "Cover changes fingerprint");
      Check (Primary_Header_Count (S) = 6, "Cover removes one header");
      Uncover (S, C);
      Fp2 := Structure_Fingerprint (S);
      Check (Fp2 = Fp0, "Uncover restores fingerprint");
      Check (Primary_Header_Count (S) = 7, "headers restored");
      Check (Header_Size (S, C) = Sz, "Size restored");

      --  Cover every primary once then uncover in reverse.
      declare
         Order : array (1 .. 7) of Node_Id;
         N : Natural := 0;
         X : Node_Id := S.Nodes (Root_Id).R;
      begin
         while X /= Root_Id loop
            N := N + 1;
            Order (N) := X;
            X := S.Nodes (X).R;
         end loop;
         Check (N = 7, "walk 7 headers");
         Fp0 := Structure_Fingerprint (S);
         for I in 1 .. N loop
            Cover (S, Order (I));
         end loop;
         Check (Primary_Header_Count (S) = 0, "all covered");
         for I in reverse 1 .. N loop
            Uncover (S, Order (I));
         end loop;
         Check (Structure_Fingerprint (S) = Fp0, "full cover/uncover restore");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("7. MRV Choose_Column");
   ---------------------------------------------------------------------
   declare
      S : Solver;
      --  Col1 has two 1s, Col2 has one → MRV picks Col2.
      M : constant Bool_Matrix (1 .. 2, 1 .. 2) :=
        [[True, True],
         [True, False]];
      C : Node_Id;
   begin
      Build_From_Matrix (S, M);
      Check (Header_Size (S, 1) = 2, "MRV setup Size1=2");
      Check (Header_Size (S, 2) = 1, "MRV setup Size2=1");
      C := Choose_Column (S);
      Check (C = 2, "MRV chooses column 2");
      Check (Min_Primary_Size (S) = 1, "Min_Primary_Size = 1");
   end;

   ---------------------------------------------------------------------
   Section ("8. Build_From_Row_Sets alias");
   ---------------------------------------------------------------------
   declare
      S : Solver;
      M : constant Bool_Matrix (1 .. 2, 1 .. 2) :=
        [[True, False], [False, True]];
      Raised : Boolean := False;
   begin
      Build_From_Row_Sets (S, 2, M);
      Check (Count_Solutions (S) = 1, "Row_Sets Id2");
      begin
         Build_From_Row_Sets (S, 3, M);
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Row_Sets col mismatch raises");
   end;

   ---------------------------------------------------------------------
   Section ("9. Secondary columns (optional cover)");
   ---------------------------------------------------------------------
   declare
      S : Solver;
      --  2 primary + 1 secondary. Rows: (P1,S), (P2,S) — secondary shared.
      --  Exact cover of primaries: both rows; secondary covered twice? No —
      --  Cover removes the other row when first is chosen... Actually with
      --  both rows covering same secondary, picking row1 covers secondary
      --  and removes row2 from P2's list → P2 becomes empty → fail.
      --  So 0 solutions when secondary conflicts.
      Conflict : constant Bool_Matrix (1 .. 2, 1 .. 3) :=
        [[True,  False, True],
         [False, True,  True]];
      --  Disjoint secondary: (P1,S1), (P2,S2) → 1 solution.
      Ok_Sec : constant Bool_Matrix (1 .. 2, 1 .. 4) :=
        [[True,  False, True,  False],
         [False, True,  False, True]];
      --  Primary-only same as Ok without needing secondary forced:
      Only_P : constant Bool_Matrix (1 .. 2, 1 .. 2) :=
        [[True, False], [False, True]];
   begin
      Build_From_Matrix (S, Conflict, Primary_Count => 2);
      Check (S.Num_Primary = 2, "secondary Num_Primary=2");
      Check (Primary_Header_Count (S) = 2, "secondary linked primaries");
      Check (S.Num_Columns = 3, "secondary total cols 3");
      Check (Count_Solutions (S) = 0, "conflicting secondary → 0");

      Build_From_Matrix (S, Ok_Sec, Primary_Count => 2);
      Check (Count_Solutions (S) = 1, "disjoint secondary → 1");

      Build_From_Matrix (S, Only_P, Primary_Count => 2);
      Check (Count_Solutions (S) = 1, "primary-only → 1");
   end;

   ---------------------------------------------------------------------
   Section ("10. N-queens counts");
   ---------------------------------------------------------------------
   declare
      Arr   : Solution_Array;
      Count : Natural;
   begin
      Check (N_Queens_Count (1) = 1, "N=1 → 1");
      Check (N_Queens_Count (2) = 0, "N=2 → 0");
      Check (N_Queens_Count (3) = 0, "N=3 → 0");
      Check (N_Queens_Count (4) = 2, "N=4 → 2");
      Check (N_Queens_Count (5) = 10, "N=5 → 10");
      Check (N_Queens_Count (6) = 4, "N=6 → 4");
      Check (N_Queens_Count (7) = 40, "N=7 → 40");
      Check (N_Queens_Count (8) = 92, "N=8 → 92");

      N_Queens_Solve (4, Arr, Count, 10);
      Check (Count = 2, "N=4 Solve_All count 2");
      Check (Arr (1).Length = 4 and then Arr (2).Length = 4,
             "N=4 each sol has 4 rows");

      N_Queens_Solve (5, Arr, Count, 20);
      Check (Count = 10, "N=5 Solve_All count 10");

      --  Cap truncates storage.
      N_Queens_Solve (5, Arr, Count, 3);
      Check (Count = 3, "N=5 Cap=3 truncates");
   end;

   ---------------------------------------------------------------------
   Section ("11. N-queens build structure");
   ---------------------------------------------------------------------
   declare
      S : Solver;
   begin
      Build_N_Queens (S, 4);
      Check (S.Num_Columns = 22, "N=4 columns 22");
      Check (S.Num_Primary = 8, "N=4 primary 8");
      Check (S.Num_Rows = 16, "N=4 rows 16");
      Check (Primary_Header_Count (S) = 8, "N=4 linked 8");
      --  Each queen position contributes 4 ones; sizes on row cols = N.
      declare
         Col : Node_Id;
         K   : Integer;
      begin
         K := 1;
         while K <= 4 loop
            Col := Node_Id (K);
            Check (Header_Size (S, Col) = 4,
                   "N=4 row-col Size=4 #" & K'Image);
            K := K + 1;
         end loop;
      end;

      Build_N_Queens (S, 8);
      Check (S.Num_Columns = 46, "N=8 columns 46");
      Check (S.Num_Primary = 16, "N=8 primary 16");
      Check (S.Num_Rows = 64, "N=8 rows 64");
      Check (S.Last_Node = Node_Id (46 + 64 * 4),
             "N=8 node pool size");
   end;

   ---------------------------------------------------------------------
   Section ("12. Cap / Solve one vs all");
   ---------------------------------------------------------------------
   declare
      S : Solver;
      M : constant Bool_Matrix (1 .. 3, 1 .. 1) :=
        [[True], [True], [True]];
      Arr : Solution_Array;
      Count : Natural;
      Found : Solution;
      Ok : Boolean;
   begin
      Build_From_Matrix (S, M);
      Check (Count_Solutions (S, 100) = 3, "three singleton rows");
      Build_From_Matrix (S, M);
      Solve_All (S, Arr, Count, 2);
      Check (Count = 2, "Cap=2 stops early");
      Build_From_Matrix (S, M);
      Solve (S, Found, Ok);
      Check (Ok and then Found.Length = 1, "Solve returns one");
   end;

   ---------------------------------------------------------------------
   Section ("13. Exceptions / invalid args");
   ---------------------------------------------------------------------
   declare
      S : Solver;
      Raised : Boolean;
      Bad : constant Bool_Matrix (1 .. 1, 2 .. 2) := [[True]];
   begin
      Raised := False;
      begin
         Build_From_Matrix (S, Bad);
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "non-1 first col index raises");

      Raised := False;
      begin
         declare
            Ignore : Natural;
         begin
            Ignore := Header_Size (S, 0);
            pragma Unreferenced (Ignore);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Header_Size(Root) raises");

      Raised := False;
      begin
         Build_From_Matrix (S, [[True]], Primary_Count => 2);
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Primary_Count > cols raises");
   end;

   ---------------------------------------------------------------------
   Section ("14. Cover then search still consistent");
   ---------------------------------------------------------------------
   declare
      S : Solver;
      Fp : Natural;
      C  : Node_Id;
   begin
      Build_Knuth_Example (S);
      Fp := Structure_Fingerprint (S);
      Check (Count_Solutions (S) = 1, "search after build");
      --  After full search, structure must be restored.
      Check (Structure_Fingerprint (S) = Fp, "search restores structure");
      Check (Primary_Header_Count (S) = 7, "headers after search");

      Build_Knuth_Example (S);
      C := Choose_Column (S);
      Cover (S, C);
      Uncover (S, C);
      Check (Count_Solutions (S) = 1, "after manual cover/uncover");
   end;

   ---------------------------------------------------------------------
   Section ("15. Small tiling-style exact cover");
   ---------------------------------------------------------------------
   --  Cover a 2x2 board with two dominoes: vertical or horizontal pairs.
   --  Columns = 4 cells. Rows = placements:
   --    H top: cells 1,2; H bot: 3,4; V left: 1,3; V right: 2,4.
   declare
      S : Solver;
      M : constant Bool_Matrix (1 .. 4, 1 .. 4) :=
        [[True,  True,  False, False],   -- H top
         [False, False, True,  True],    -- H bot
         [True,  False, True,  False],   -- V left
         [False, True,  False, True]];   -- V right
      Count : Natural;
   begin
      Build_From_Matrix (S, M);
      Count := Count_Solutions (S);
      Check (Count = 2, "2x2 domino tilings = 2");
   end;

   ---------------------------------------------------------------------
   Section ("16. Identity / permutation covers");
   ---------------------------------------------------------------------
   declare
      S : Solver;
      Id3 : constant Bool_Matrix (1 .. 3, 1 .. 3) :=
        [[True, False, False],
         [False, True, False],
         [False, False, True]];
      --  All permutation rows for S2 (2 cols): (1,0),(0,1) only one cover;
      --  For 2 cols with both perm rows: 1 solution.
      Perm2 : constant Bool_Matrix (1 .. 2, 1 .. 2) :=
        [[True, False], [False, True]];
   begin
      Build_From_Matrix (S, Id3);
      Check (Count_Solutions (S) = 1, "I3 one solution");
      Build_From_Matrix (S, Perm2);
      Check (Count_Solutions (S) = 1, "perm2 one solution");
      Check (Min_Primary_Size (S) = 1, "perm2 min size 1");
   end;

   ---------------------------------------------------------------------
   Section ("17. Solve_All Cap vs Max_Solutions");
   ---------------------------------------------------------------------
   declare
      S : Solver;
      --  5 singleton rows on one column → 5 sols.
      M : constant Bool_Matrix (1 .. 5, 1 .. 1) :=
        [[True], [True], [True], [True], [True]];
      Arr : Solution_Array;
      Count : Natural;
   begin
      Build_From_Matrix (S, M);
      Solve_All (S, Arr, Count, 100);
      Check (Count = 5, "5 sols with large Cap");
      Build_From_Matrix (S, M);
      Check (Count_Solutions (S, 3) = 3, "count Cap=3");
      Build_From_Matrix (S, M);
      Check (Count_Solutions (S, 0) = 0, "count Cap=0");
   end;

   ---------------------------------------------------------------------
   New_Line;
   Put_Line
     ("Pass_Count =" & Pass_Count'Image
      & "  Fail_Count =" & Fail_Count'Image);
   if Fail_Count = 0 then
      Put_Line ("ALL PASSED");
   else
      Put_Line ("SOME FAILED");
   end if;

   if Fail_Count /= 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
