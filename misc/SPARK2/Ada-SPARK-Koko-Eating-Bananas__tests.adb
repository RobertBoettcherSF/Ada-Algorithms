with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Koko_Eating_Bananas; use Koko_Eating_Bananas;

procedure Tests is
   P : constant Pile_Array := [3, 6, 7, 11, 2, 4, 5, 8];
begin
   Assert (Minimum_Speed (P, 8) = 11);
   Assert (Minimum_Speed (P, 16) = 4);
   Put_Line ("PASS Koko_Eating_Bananas");
end Tests;
