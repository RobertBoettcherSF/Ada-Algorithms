pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Min_Cost_To_Connect_All_Points; use Min_Cost_To_Connect_All_Points;
procedure Tests is
   P : Point_Array := ((0, 0), (2, 2), (3, 10), (5, 2), (7, 0), (8, 2), (10, 3), (12, 1));
   Answer : Total_Cost;
begin
   Compute (P, Answer);
   Assert (Answer = 29);
   Put_Line ("PASS Min_Cost_To_Connect_All_Points");
end Tests;
