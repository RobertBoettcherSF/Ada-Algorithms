with Ada.Assertions; use Ada.Assertions;
with Game_Of_Life_Step; use Game_Of_Life_Step;
procedure Tests is
   Input : Board := ((0, 1, 0), (0, 1, 0), (0, 1, 0));
   Expected : constant Board := ((0, 0, 0), (1, 1, 1), (0, 0, 0));
begin
   Step (Input);
   Assert (Input = Expected);
end Tests;
