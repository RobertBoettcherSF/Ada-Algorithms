with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Peak_Index_In_Mountain_Array; use Peak_Index_In_Mountain_Array;

procedure Tests is
   A : constant Mountain_Array := [1, 3, 7, 12, 10, 6, 2, 0];
begin
   Assert (Peak_Index (A) = 4);
   Put_Line ("PASS Peak_Index_In_Mountain_Array");
end Tests;
