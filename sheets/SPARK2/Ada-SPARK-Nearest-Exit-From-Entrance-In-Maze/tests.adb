with Ada.Assertions; use Ada.Assertions;
with Nearest_Exit_From_Entrance_In_Maze; use Nearest_Exit_From_Entrance_In_Maze;

procedure Tests is
   G : Grid := [others => [others => 0]];
begin
   Assert (Open_Count (G) = 0);
   G (1, 1) := 1;
   G (4, 5) := 1;
   G (8, 8) := 1;
   Assert (Open_Count (G) = 3);
end Tests;
