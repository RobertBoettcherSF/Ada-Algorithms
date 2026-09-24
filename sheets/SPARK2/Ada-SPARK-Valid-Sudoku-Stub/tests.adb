with Ada.Assertions; use Ada.Assertions;
with Valid_Sudoku_Stub; use Valid_Sudoku_Stub;
procedure Tests is
   Good : constant Board :=
     ((1, 2, 3), (2, 3, 1), (3, 1, 2));
   Bad : constant Board :=
     ((1, 1, 3), (2, 3, 1), (3, 1, 2));
begin
   Assert (Is_Valid (Good));
   Assert (not Is_Valid (Bad));
end Tests;
