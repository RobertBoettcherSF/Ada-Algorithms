with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Majority_Element_II; use Majority_Element_II;
procedure Tests is
   A : constant Input_Array := [1, 2, 1, 3, 1, 2, 1, 4];
   R : constant Result_Array := Find (A);
begin
   Assert (R (1) = 1);
   Assert (R (2) = 0);
   Put_Line ("PASS Majority_Element_II");
end Tests;
