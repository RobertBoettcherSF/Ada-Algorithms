--  Standalone test suite for Algorithm_X (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with Algorithm_X; use Algorithm_X;

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
      R   : Solution := Sol;
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
   Put_Line ("Algorithm_X test suite");
   Put_Line ("======================");

   ---------------------------------------------------------------------
   Section ("1. Caps and Clear");
   ---------------------------------------------------------------------
   declare
      S : Solver;
   begin
      Check (N_Queens_Column_Count (5) = 28, "Queens cols N=5 = 28");
      Check (N_Queens_Column_Count (2) < N_Queens_Column_Count (3),
             "Queens cols grow with N");
      Check (N_Queens_Column_Count (3) < N_Queens_Column_Count (6),
             "Queens cols N=3 < N=6");
      Check (N_Queens_Column_Count (4) = Column_Count (2 * 4 + 2 * (2 * 4 - 1)),
             "Queens 2N primary + 2*(2N-1) secondary");
      Check (N_Queens_Column_Count (1) = 4, "Queens cols N=1 = 4");
      Check (N_Queens_Column_Count (4) = 22, "Queens cols N=4 = 22");
      Check (N_Queens_Column_Count (6) = 34, "Queens cols N=6 = 34");
      Check (N_Queens_Column_Count (6) = Column_Count (6 * 6 - 2),
             "Queens formula 6N-2");
      Clear (S);
      Check (S.Num_Rows = 0, "Clear Num_Rows 0");
      Check (S.Num_Columns = 0, "Clear Num_Columns 0");
      Check (S.Num_Primary = 0, "Clear Num_Primary 0");
      Check (Active_Primary_Count (S) = 0, "Clear active primary 0");
      Check (Choose_Column (S) = 0, "Clear Choose_Column → 0");
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
      Check (Count_Solutions (S, 10) = 1, "empty Count_Solutions = 1");
      Solve (S, Found, Ok);
      Check (Ok, "empty Solve Success");
      Check (Found.Length = 0, "empty solution length 0");
      Clear (S);
      Solve_All (S, Arr, Count, 5);
      Check (Count = 1 and then Arr (1).Length = 0, "empty Solve_All");
      Check (Active_Primary_Count (S) = 0, "empty still no primaries");
   end;

   ---------------------------------------------------------------------
   Section ("3. Unsatisfiable matrices → 0 solutions");
   ---------------------------------------------------------------------
   declare
      S : Solver;
      M0 : constant Bool_Matrix (1 .. 1, 1 .. 1) := [[False]];
      M1 : constant Bool_Matrix (1 .. 1, 1 .. 2) := [[True, False]];
      Found : Solution;
      Ok    : Boolean;
   begin
      Build_From_Matrix (S, M0);
      Check (S.Num_Columns = 1, "unsat empty-col cols=1");
      Check (Column_Ones (S, 1) = 0, "unsat empty-col Ones=0");
      Check (Count_Solutions (S) = 0, "unsat empty-col 0 sols");
      Build_From_Matrix (S, M1);
      Check (Column_Ones (S, 1) = 1, "partial cover Ones col1");
      Check (Column_Ones (S, 2) = 0, "partial cover Ones col2=0");
      Check (Count_Solutions (S) = 0, "partial cover 0 sols");
      Solve (S, Found, Ok);
      Check (not Ok, "partial cover Solve fails");
   end;

   ---------------------------------------------------------------------
   Section ("4. Tiny exact covers");
   ---------------------------------------------------------------------
   declare
      S : Solver;
      Id2 : constant Bool_Matrix (1 .. 2, 1 .. 2) :=
        [[True, False], [False, True]];
      One : constant Bool_Matrix (1 .. 1, 1 .. 1) := [[True]];
      Dup : constant Bool_Matrix (1 .. 2, 1 .. 1) := [[True], [True]];
      Full : constant Bool_Matrix (1 .. 2, 1 .. 2) :=
        [[True, True], [True, True]];
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
      Check (Column_Ones (S, 1) = 1 and then Column_Ones (S, 2) = 1,
             "Id2 Ones");
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

      --  Two full rows → two singleton solutions.
      Build_From_Matrix (S, Full);
      Check (Count_Solutions (S) = 2, "full 2x2 two sols");
   end;

   ---------------------------------------------------------------------
   Section ("5. Knuth classic example (unique {B,D,F} = {2,4,6})");
   ---------------------------------------------------------------------
   declare
      S      : Solver;
      Found  : Solution;
      Ok     : Boolean;
      Arr    : Solution_Array;
      Count  : Natural;
      Expect : constant Solution :=
        (Length => 3, Rows => [2, 4, 6, others => 0]);
   begin
      Check (Knuth_Example_Solution_Count = 1, "Knuth count helper = 1");
      Build_Knuth_Example (S);
      Check (S.Num_Columns = 7, "Knuth 7 columns");
      Check (S.Num_Rows = 6, "Knuth 6 rows");
      Check (S.Num_Primary = 7, "Knuth all primary");
      Check (Active_Primary_Count (S) = 7, "Knuth active 7");
      Check (Active_Row_Count (S) = 6, "Knuth active rows 6");
      Check (Count_Solutions (S) = 1, "Knuth Count_Solutions");
      Build_Knuth_Example (S);
      Solve (S, Found, Ok);
      Check (Ok, "Knuth Solve ok");
      Check (Same_Rows (Found, Expect), "Knuth solution {2,4,6}");
      Build_Knuth_Example (S);
      Solve_All (S, Arr, Count, 10);
      Check (Count = 1 and then Same_Rows (Arr (1), Expect),
             "Knuth Solve_All");
   end;

   ---------------------------------------------------------------------
   Section ("6. MRV column choice");
   ---------------------------------------------------------------------
   declare
      S : Solver;
      --  Col1 has two 1s, Col2 has one 1 → MRV picks Col2.
      M : constant Bool_Matrix (1 .. 2, 1 .. 2) :=
        [[True, True],
         [True, False]];
      C : Column_Id;
   begin
      Build_From_Matrix (S, M);
      Check (Column_Ones (S, 1) = 2, "MRV setup Ones(1)=2");
      Check (Column_Ones (S, 2) = 1, "MRV setup Ones(2)=1");
      C := Choose_Column (S);
      Check (C = 2, "MRV chooses column 2");

      Build_Knuth_Example (S);
      --  Wikipedia: lowest number of 1s is two; first such is column 1.
      Check (Column_Ones (S, 1) = 2, "Knuth Ones(1)=2");
      Check (Column_Ones (S, 2) = 2, "Knuth Ones(2)=2");
      Check (Column_Ones (S, 3) = 2, "Knuth Ones(3)=2");
      Check (Column_Ones (S, 4) = 3, "Knuth Ones(4)=3");
      Check (Column_Ones (S, 5) = 2, "Knuth Ones(5)=2");
      Check (Column_Ones (S, 6) = 2, "Knuth Ones(6)=2");
      Check (Column_Ones (S, 7) = 4, "Knuth Ones(7)=4");
      C := Choose_Column (S);
      Check (C = 1, "Knuth MRV first min-col is 1");
   end;

   ---------------------------------------------------------------------
   Section ("7. Select_Row / Restore backtrack");
   ---------------------------------------------------------------------
   declare
      S : Solver;
      Fp0, Fp1, Fp2 : Natural;
      St : Active_State;
      Prim0 : Natural;
      Rows0 : Natural;
   begin
      Build_Knuth_Example (S);
      Fp0 := State_Fingerprint (S);
      Prim0 := Active_Primary_Count (S);
      Rows0 := Active_Row_Count (S);
      St := Snapshot (S);

      --  Selecting row A (1) covers cols 1,4,7 and deletes A,B,C,E,F.
      Select_Row (S, 1);
      Fp1 := State_Fingerprint (S);
      Check (Fp1 /= Fp0, "Select_Row changes fingerprint");
      Check (Active_Primary_Count (S) = 4, "after A: 4 cols left (2,3,5,6)");
      Check (Active_Row_Count (S) = 1, "after A: only row D left");
      Check (not S.Active_Row (1), "row A inactive");
      Check (not S.Active_Col (1), "col 1 inactive");
      Check (S.Active_Col (2), "col 2 still active");
      Check (S.Active_Row (4), "row D still active");

      Restore (S, St);
      Fp2 := State_Fingerprint (S);
      Check (Fp2 = Fp0, "Restore restores fingerprint");
      Check (Active_Primary_Count (S) = Prim0, "primaries restored");
      Check (Active_Row_Count (S) = Rows0, "rows restored");

      --  Selecting B (2) then D (4) then F (6) should empty primaries.
      St := Snapshot (S);
      Select_Row (S, 2);
      Check (Active_Primary_Count (S) = 5, "after B: 5 cols");
      Select_Row (S, 4);
      Check (Active_Primary_Count (S) = 2, "after B,D: cols 2,7");
      Select_Row (S, 6);
      Check (Active_Primary_Count (S) = 0, "after B,D,F: done");
      Check (Active_Row_Count (S) = 0, "after B,D,F: no rows");
      Restore (S, St);
      Check (Active_Primary_Count (S) = 7, "full restore after path");
   end;

   ---------------------------------------------------------------------
   Section ("8. Build_From_Row_Sets and secondary columns");
   ---------------------------------------------------------------------
   declare
      S : Solver;
      --  Primary col1 must be covered; secondary col2 optional.
      --  Row1 covers both; slack-style row2 covers only secondary.
      M : constant Bool_Matrix (1 .. 2, 1 .. 2) :=
        [[True, True],
         [False, True]];
      Found : Solution;
      Ok    : Boolean;
      Count : Natural;
   begin
      Build_From_Row_Sets (S, 2, M, Primary_Count => 1);
      Check (S.Num_Primary = 1, "secondary: Num_Primary=1");
      Check (S.Num_Columns = 2, "secondary: Num_Columns=2");
      Check (Active_Primary_Count (S) = 1, "secondary: one active primary");
      --  Choosing among primaries only → column 1.
      Check (Choose_Column (S) = 1, "secondary: Choose picks primary");
      --  Selecting row1 covers primary (+ secondary); success.
      Check (Count_Solutions (S) = 1, "secondary: one solution");
      Build_From_Row_Sets (S, 2, M, Primary_Count => 1);
      Solve (S, Found, Ok);
      Check (Ok and then Found.Length = 1 and then Found.Rows (1) = 1,
             "secondary: solution is row 1");

      --  All-primary on same matrix: need both cols → only row1 works
      --  (row2 alone leaves col1 uncovered; row1+row2 conflict on col2).
      Build_From_Matrix (S, M, 0);
      Count := Count_Solutions (S);
      Check (Count = 1, "all-primary same matrix still 1 sol");
   end;

   ---------------------------------------------------------------------
   Section ("9. N-queens exact-cover counts");
   ---------------------------------------------------------------------
   declare
      Arr   : Solution_Array;
      Count : Natural;
   begin
      Check (N_Queens_Count (1) = 1, "Queens N=1 → 1");
      Check (N_Queens_Count (2) = 0, "Queens N=2 → 0");
      Check (N_Queens_Count (3) = 0, "Queens N=3 → 0");
      Check (N_Queens_Count (4) = 2, "Queens N=4 → 2");
      Check (N_Queens_Count (5) = 10, "Queens N=5 → 10");
      Check (N_Queens_Count (6) = 4, "Queens N=6 → 4");

      N_Queens_Solve (4, Arr, Count, 10);
      Check (Count = 2, "Queens N=4 Solve_All count");
      Check (Arr (1).Length = 4 and then Arr (2).Length = 4,
             "Queens N=4 each sol length 4");

      declare
         S : Solver;
      begin
         Build_N_Queens (S, 4);
         Check (S.Num_Columns = 22, "Build_N_Queens N=4 cols");
         Check (S.Num_Primary = 8, "Build_N_Queens N=4 primary 2N");
         Check (S.Num_Rows = 16, "Build_N_Queens N=4 rows N^2");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("10. Solve restores state; Cap limits");
   ---------------------------------------------------------------------
   declare
      S : Solver;
      Fp0, Fp1 : Natural;
      Arr : Solution_Array;
      Count : Natural;
      Found : Solution;
      Ok : Boolean;
      Dup : constant Bool_Matrix (1 .. 3, 1 .. 1) :=
        [[True], [True], [True]];
   begin
      Build_Knuth_Example (S);
      Fp0 := State_Fingerprint (S);
      Ok := False;
      Solve (S, Found, Ok);
      Check (Ok, "restore-test Solve ok");
      Fp1 := State_Fingerprint (S);
      Check (Fp1 = Fp0, "Solve restores fingerprint");
      Check (Active_Primary_Count (S) = 7, "Solve restores primaries");
      Check (Count_Solutions (S) = 1, "Count after Solve still 1");

      Build_From_Matrix (S, Dup);
      Solve_All (S, Arr, Count, Cap => 2);
      Check (Count = 2, "Cap=2 stops at 2 of 3");
      Check (Count_Solutions (S, Cap => 2) = 2, "Count_Solutions Cap=2");
      Check (Count_Solutions (S, Cap => 10) = 3, "Count_Solutions all 3");
      Check (Count_Solutions (S, Cap => 0) = 0, "Cap=0 yields 0");
   end;

   ---------------------------------------------------------------------
   Section ("11. Exceptions / capacity edges");
   ---------------------------------------------------------------------
   declare
      S : Solver;
      Raised : Boolean;
   begin
      Raised := False;
      begin
         declare
            Bad : constant Bool_Matrix (2 .. 3, 1 .. 1) := [[True], [True]];
         begin
            Build_From_Matrix (S, Bad);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "non-1-based rows → Invalid_Argument");

      Raised := False;
      begin
         declare
            M : constant Bool_Matrix (1 .. 1, 1 .. 2) := [[True, False]];
         begin
            Build_From_Row_Sets (S, 3, M);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Row_Sets col mismatch → Invalid_Argument");

      Raised := False;
      begin
         declare
            M : constant Bool_Matrix (1 .. 1, 1 .. 2) := [[True, True]];
         begin
            Build_From_Matrix (S, M, Primary_Count => 3);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Primary_Count > cols → Invalid_Argument");

      Raised := False;
      begin
         Build_Knuth_Example (S);
         declare
            Unused : Natural := Column_Ones (S, 0);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Column_Ones(0) → Invalid_Argument");

      Raised := False;
      begin
         Build_Knuth_Example (S);
         Select_Row (S, 0);
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Select_Row(0) → Invalid_Argument");
   end;

   ---------------------------------------------------------------------
   Section ("12. Disjoint union / multiple solutions shape");
   ---------------------------------------------------------------------
   declare
      S : Solver;
      --  Two independent identity blocks → one solution (all four rows)
      --  if we use 4 cols; or for 2 cols with 3 overlapping options.
      Id3 : constant Bool_Matrix (1 .. 3, 1 .. 3) :=
        [[True, False, False],
         [False, True, False],
         [False, False, True]];
      --  Two ways to cover two cols with disjoint pairs.
      Pairs : constant Bool_Matrix (1 .. 4, 1 .. 2) :=
        [[True, False],
         [True, False],
         [False, True],
         [False, True]];
      Arr : Solution_Array;
      Count : Natural;
      Found : Solution;
      Ok : Boolean;
   begin
      Build_From_Matrix (S, Id3);
      Check (Count_Solutions (S) = 1, "Id3 unique");
      Solve (S, Found, Ok);
      Check (Ok and then Found.Length = 3, "Id3 length 3");

      Build_From_Matrix (S, Pairs);
      --  Choose one of {1,2} for col1 and one of {3,4} for col2 → 4 sols.
      Check (Count_Solutions (S) = 4, "pairs 2x2 = 4 sols");
      Solve_All (S, Arr, Count, 10);
      Check (Count = 4, "pairs Solve_All 4");
      Check (Arr (1).Length = 2, "pairs sol length 2");
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
