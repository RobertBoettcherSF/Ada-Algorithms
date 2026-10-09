pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Find_Center_Of_Star_Graph; use Find_Center_Of_Star_Graph;
with Own_Checks;
procedure Tests is
   E : constant Edge_List :=
     [1 => (From => 3, To => 1), 2 => (From => 3, To => 2),
      3 => (From => 3, To => 4), 4 => (From => 3, To => 5),
      5 => (From => 3, To => 6), 6 => (From => 3, To => 7),
      7 => (From => 3, To => 8), 8 => (From => 3, To => 9),
      9 => (From => 3, To => 10), 10 => (From => 3, To => 11),
      11 => (From => 3, To => 12), 12 => (From => 3, To => 13),
      13 => (From => 3, To => 14), 14 => (From => 3, To => 15),
      15 => (From => 3, To => 16)];
   --  Hand-built (agent A3): centre 16 written as the To end of every edge,
   --  centre 1 (the first vertex the search looks at), and a path
   --  1 - 2 - .. - 16, which has no centre.
   To_16 : Edge_List;
   From_1 : Edge_List;
   Path  : Edge_List;
begin
   for I in To_16'Range loop
      To_16 (I) := (From => I, To => 16);
      From_1 (I) := (From => 1, To => I + 1);
      Path (I) := (From => I, To => I + 1);
   end loop;
   Assert (Find_Center (E) = 3);
   Assert (Find_Center (To_16) = 16);
   Assert (Find_Center (From_1) = 1);
   Assert (Find_Center (Path) = 0);
   Own_Checks;
end Tests;
