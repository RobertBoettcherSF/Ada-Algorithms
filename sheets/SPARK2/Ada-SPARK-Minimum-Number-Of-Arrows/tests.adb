pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Minimum_Number_Of_Arrows; use Minimum_Number_Of_Arrows;
procedure Tests is
begin
   pragma Assert (Arrows_Needed (0, 3) = 0);
   pragma Assert (Arrows_Needed (7, 3) = 3);
   Put_Line ("PASS Ada-SPARK-Minimum-Number-Of-Arrows");
end Tests;
