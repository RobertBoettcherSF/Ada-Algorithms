pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Broken_Calculator; use Broken_Calculator;
procedure Tests is
begin
   pragma Assert (Minimum_Operations (5, 2) = 3);
   pragma Assert (Minimum_Operations (2, 5) = 3);
   Put_Line ("PASS Ada-SPARK-Broken-Calculator");
end Tests;
