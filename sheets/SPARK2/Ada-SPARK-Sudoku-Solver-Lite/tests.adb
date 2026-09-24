with Ada.Assertions; use Ada.Assertions;
with Sudoku_Solver_Lite; use Sudoku_Solver_Lite;
procedure Tests is
   Good : constant Grid :=
     (1 => (1 => 1, 2 => 2, 3 => 3, 4 => 4),
      2 => (1 => 3, 2 => 4, 3 => 1, 4 => 2),
      3 => (1 => 2, 2 => 1, 3 => 4, 4 => 3),
      4 => (1 => 4, 2 => 3, 3 => 2, 4 => 1));
   Bad : Grid := Good;
begin
   Assert (Is_Valid (Good));
   Bad (4, 4) := 3;
   Assert (not Is_Valid (Bad));
end Tests;
