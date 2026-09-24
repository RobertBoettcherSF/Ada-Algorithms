pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Maximum_Units_On_A_Truck; use Maximum_Units_On_A_Truck;
procedure Tests is
begin
   pragma Assert (Max_Units (4, 5, 3) = 15);
   pragma Assert (Max_Units (2, 7, 3) = 14);
   Put_Line ("PASS Ada-SPARK-Maximum-Units-On-A-Truck");
end Tests;
