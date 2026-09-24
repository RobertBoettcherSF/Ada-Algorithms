with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Find_K_Closest; use Find_K_Closest;
procedure Tests is
   A : constant Input_Array := [-10, -3, 0, 4, 7, 11, 15, 20];
begin
   Assert (Closest_Index (A, 6) = 5);
   Assert (Closest_Index (A, -8) = 1);
   Assert (Closest_Index (A, 13) = 6);
   Put_Line ("PASS Find_K_Closest");
end Tests;
