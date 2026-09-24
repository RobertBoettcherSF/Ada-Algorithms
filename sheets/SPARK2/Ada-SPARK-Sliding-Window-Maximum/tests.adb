pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Sliding_Window_Maximum; use Sliding_Window_Maximum;
procedure Tests is
   A : constant Input_Array := [1, 3, -1, -3, 5, 3, 6, 7];
   R : constant Output_Array := Maximums (A);
begin
   Assert (R = [3, 3, 5, 5, 6, 7]);
end Tests;
