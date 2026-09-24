with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Split_Array_Largest_Sum; use Split_Array_Largest_Sum;

procedure Tests is
   A : constant Input_Array := [7, 2, 5, 10, 8, 1, 3, 4];
begin
   Assert (Largest_Sum (A, 2) = 24);
   Assert (Largest_Sum (A, 8) = 10);
   Put_Line ("PASS Split_Array_Largest_Sum");
end Tests;
