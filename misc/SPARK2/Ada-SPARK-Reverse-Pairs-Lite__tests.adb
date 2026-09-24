with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Reverse_Pairs; use Reverse_Pairs;
procedure Tests is
   A : constant Input_Array := [1, 3, 2, 3, 1, 0, 4, 2];
begin
   Assert (Reverse_Pairs.Count (A) = 7);
   Put_Line ("PASS Reverse_Pairs");
end Tests;
