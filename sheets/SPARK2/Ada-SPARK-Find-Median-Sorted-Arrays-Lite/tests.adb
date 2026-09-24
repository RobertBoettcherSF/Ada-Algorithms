pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Median_Sorted_Arrays_Lite; use Median_Sorted_Arrays_Lite;
procedure Tests is
   A : Values := (1 => 1, 2 => 3, others => 0);
   B : Values := (1 => 2, 2 => 4, others => 0);
begin
   Assert (Median (A, 2, B, 2) = 2);
   Put_Line ("PASS Median Sorted Arrays Lite");
end Tests;
