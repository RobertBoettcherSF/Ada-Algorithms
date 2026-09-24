pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Lemonade_Change; use Lemonade_Change;
procedure Tests is
begin
   pragma Assert (Can_Make_Change (9, 1, 2));
   pragma Assert (not Can_Make_Change (3, 1, 1));
   Put_Line ("PASS Ada-SPARK-Lemonade-Change");
end Tests;
