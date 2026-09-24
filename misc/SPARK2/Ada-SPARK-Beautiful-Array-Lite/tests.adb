with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Beautiful_Array; use Beautiful_Array;
procedure Tests is
   A : constant Input_Array := [1, 5, 3, 7, 2, 6, 4, 8];
   B : constant Input_Array := [1, 2, 3, 4, 5, 6, 7, 8];
begin
   Assert (Is_Beautiful (A));
   Assert (not Is_Beautiful (B));
   Put_Line ("PASS Beautiful_Array");
end Tests;
