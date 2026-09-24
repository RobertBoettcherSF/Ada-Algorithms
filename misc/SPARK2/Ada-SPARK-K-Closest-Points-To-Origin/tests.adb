pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with K_Closest_Points; use K_Closest_Points;
procedure Tests is
   P : Point_Array := (1 => (3, 4), 2 => (1, 1), 3 => (10, 0), others => (0, 0));
begin
   Assert (Kth_Distance (P, 3, 2) = 25);
   Put_Line ("PASS K Closest Points");
end Tests;
