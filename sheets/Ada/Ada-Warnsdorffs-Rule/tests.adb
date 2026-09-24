-- tests.adb
-- Executable V&V test suite proving the code operates correctly.

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Warnsdorff; use Warnsdorff;

procedure Tests is
   Grid_5x5 : Board_Grid (1 .. 5, 1 .. 5);
   Grid_6x6 : Board_Grid (1 .. 6, 1 .. 6);
   Grid_3x3 : Board_Grid (1 .. 3, 1 .. 3);
   Grid_4x4 : Board_Grid (1 .. 4, 1 .. 4);
   Grid_1x1 : Board_Grid (1 .. 1, 1 .. 1);
   Success  : Boolean;
begin
   Put_Line ("Starting V&V Test Suite for Warnsdorff's Rule...");
   Put_Line ("------------------------------------------------");

   -- TEST 1 - Functional Correctness (Basic 5x5)
   Put_Line ("TEST 1 - Basic Variant on 5x5 Board");
   Solve_Tour (5, 1, 1, Basic, Grid_5x5, Success);
   Put_Line ("  1.1 Assert algorithm successfully completes tour");
   Assert (Success = True, "Failed to complete 5x5 basic tour");
   Put_Line ("      PASS");
   Put_Line ("  1.2 Assert generated tour sequence is mathematically valid");
   Assert (Is_Valid_Tour (Grid_5x5, 5) = True, "5x5 basic tour contains invalid moves");
   Put_Line ("      PASS");

   -- TEST 2 - Functional Correctness (Pohl Variant 5x5)
   Put_Line ("TEST 2 - Pohl Tie-Breaking on 5x5 Board");
   Solve_Tour (5, 1, 1, Pohl, Grid_5x5, Success);
   Put_Line ("  2.1 Assert Pohl algorithm successfully completes tour");
   Assert (Success = True, "Failed to complete 5x5 Pohl tour");
   Put_Line ("      PASS");
   Put_Line ("  2.2 Assert Pohl sequence validation");
   Assert (Is_Valid_Tour (Grid_5x5, 5) = True, "5x5 Pohl tour contains invalid moves");
   Put_Line ("      PASS");

   -- TEST 3 - Edge Case (Even dimensions 6x6)
   Put_Line ("TEST 3 - Basic Variant on 6x6 Board");
   Solve_Tour (6, 1, 1, Basic, Grid_6x6, Success);
   Put_Line ("  3.1 Assert successful resolution on even dimensional grid");
   Assert (Success = True, "Failed to complete 6x6 tour");
   Put_Line ("      PASS");
   Put_Line ("  3.2 Assert 6x6 mathematically valid");
   Assert (Is_Valid_Tour (Grid_6x6, 6) = True, "6x6 basic tour invalid");
   Put_Line ("      PASS");

   -- TEST 4 - Boundary & Exception Handling
   Put_Line ("TEST 4 - Start Position Out of Bounds");
   Put_Line ("  4.1 Assert Invalid_Start_Position is raised on X > Size");
   begin
      Solve_Tour (5, 6, 1, Basic, Grid_5x5, Success);
      Assert (False, "Expected Invalid_Start_Position not raised");
   exception
      when Invalid_Start_Position =>
         Put_Line ("      PASS");
   end;
   Put_Line ("  4.2 Assert Invalid_Start_Position is raised on Y > Size");
   begin
      Solve_Tour (5, 1, 6, Basic, Grid_5x5, Success);
      Assert (False, "Expected Invalid_Start_Position not raised");
   exception
      when Invalid_Start_Position =>
         Put_Line ("      PASS");
   end;

   -- TEST 5 - Impossible Board Configuration (3x3)
   Put_Line ("TEST 5 - Solvability Failure Case (3x3 Board)");
   Solve_Tour (3, 1, 1, Basic, Grid_3x3, Success);
   Put_Line ("  5.1 Assert algorithm fails gracefully (returns False) for 3x3");
   Assert (Success = False, "Algorithm erroneously reported success on 3x3");
   Put_Line ("      PASS");

   -- TEST 6 - Impossible Board Configuration (4x4)
   Put_Line ("TEST 6 - Solvability Failure Case (4x4 Board)");
   Solve_Tour (4, 1, 1, Basic, Grid_4x4, Success);
   Put_Line ("  6.1 Assert algorithm fails gracefully (returns False) for 4x4");
   Assert (Success = False, "Algorithm erroneously reported success on 4x4");
   Put_Line ("      PASS");

   -- TEST 7 - Trivial Board Integrity
   Put_Line ("TEST 7 - Trivial Board (1x1)");
   Solve_Tour (1, 1, 1, Basic, Grid_1x1, Success);
   Put_Line ("  7.1 Assert algorithm safely resolves a 1x1 board");
   Assert (Success = True, "1x1 failed to return true");
   Put_Line ("      PASS");
   Put_Line ("  7.2 Assert valid move integrity on 1x1");
   Assert (Is_Valid_Tour (Grid_1x1, 1) = True, "1x1 tour verification failed");
   Put_Line ("      PASS");

   Put_Line ("------------------------------------------------");
   Put_Line ("ALL TESTS PASSED SUCCESSFULLY.");
end Tests;
