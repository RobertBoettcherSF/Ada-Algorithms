with Ada.Assertions; use Ada.Assertions;
with Maximal_Rectangle; use Maximal_Rectangle;
procedure Tests is
   M : constant Matrix :=
     [1 => [1 => 1, 2 => 0, 3 => 1, 4 => 0],
      2 => [1 => 1, 2 => 0, 3 => 1, 4 => 1],
      3 => [1 => 1, 2 => 1, 3 => 1, 4 => 1],
      4 => [others => 0]];
begin
   Assert (Max_Area (M, 3, 4) = 4);
end Tests;
