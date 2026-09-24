with Ada.Assertions; use Ada.Assertions; with Ada.Text_IO; use Ada.Text_IO;
with Kth_Largest_Array; use Kth_Largest_Array;
procedure Tests is A : constant Input_Array := [3, 2, 1, 5, 6, 4, 9, 0]; begin
   Assert (Kth_Largest (A, 1) = 9); Assert (Kth_Largest (A, 2) = 6); Assert (Kth_Largest (A, 8) = 0);
   Put_Line ("PASS Kth_Largest_Array");
end Tests;
