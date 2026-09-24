pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions; with Ada.Text_IO; use Ada.Text_IO; with Disjoint_Set_Forest; use Disjoint_Set_Forest;
procedure Tests is F : Forest;
begin Initialize (F); Union (F, 1, 2); Union (F, 2, 3); Union (F, 4, 5); Assert (Same (F, 1, 3) and then not Same (F, 1, 4)); Union (F, 3, 4); Assert (Same (F, 1, 5)); Put_Line ("PASS Disjoint_Set_Forest"); end Tests;
