pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Find_Center_Of_Star_Graph; use Find_Center_Of_Star_Graph;
procedure Tests is
   E : constant Edge_List :=
     (1 => (From => 3, To => 1), 2 => (From => 3, To => 2),
      3 => (From => 3, To => 4), 4 => (From => 3, To => 5),
      5 => (From => 3, To => 6), 6 => (From => 3, To => 7),
      7 => (From => 3, To => 8), 8 => (From => 3, To => 9),
      9 => (From => 3, To => 10), 10 => (From => 3, To => 11),
      11 => (From => 3, To => 12), 12 => (From => 3, To => 13),
      13 => (From => 3, To => 14), 14 => (From => 3, To => 15),
      15 => (From => 3, To => 16));
begin
   Assert (Find_Center (E) = 3);
end Tests;
