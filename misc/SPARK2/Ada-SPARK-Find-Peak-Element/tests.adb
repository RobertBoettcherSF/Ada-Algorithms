with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Find_Peak_Element; use Find_Peak_Element;

procedure Tests is
   A : constant Input_Array := [-3, 1, 4, 2, 9, 5, 0, -1];
begin
   Assert (Find_Peak (A) = 5);
   Put_Line ("PASS Find_Peak_Element");
end Tests;
