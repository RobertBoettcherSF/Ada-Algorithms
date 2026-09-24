with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Sort_An_Array; use Sort_An_Array;
procedure Tests is
   A : Input_Array := [5, -1, 3, 3, 0, 8, 2, -4];
begin
   Sort (A);
   Assert (A = [-4, -1, 0, 2, 3, 3, 5, 8]);
   Put_Line ("PASS Sort_An_Array");
end Tests;
