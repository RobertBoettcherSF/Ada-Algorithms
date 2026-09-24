pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Union_Find; use Union_Find;
procedure Tests is
   S : Set;
begin
   Initialize (S); Union (S, 1, 2); Union (S, 2, 3); Union (S, 3, 4);
   Assert (Same (S, 1, 3) and then Same (S, 1, 4));
   Put_Line ("PASS Union_Find");
end Tests;
