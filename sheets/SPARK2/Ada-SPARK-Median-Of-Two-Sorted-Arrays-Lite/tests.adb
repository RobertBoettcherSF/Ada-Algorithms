with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Median_Of_Two_Sorted_Arrays_Lite; use Median_Of_Two_Sorted_Arrays_Lite;

procedure Tests is
   A : constant Input_Array := [1, 3, 8, 10];
   B : constant Input_Array := [2, 4, 9, 12];
begin
   Assert (Median (A, B) = 6);
   Put_Line ("PASS Median_Of_Two_Sorted_Arrays_Lite");
end Tests;
