pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Eliminate_Maximum_Number_Of_Monsters; use Eliminate_Maximum_Number_Of_Monsters;
procedure Tests is
begin
   pragma Assert (Can_Eliminate (6, 2, 3));
   pragma Assert (not Can_Eliminate (7, 2, 3));
   Put_Line ("PASS Ada-SPARK-Eliminate-Maximum-Number-Of-Monsters");
end Tests;
