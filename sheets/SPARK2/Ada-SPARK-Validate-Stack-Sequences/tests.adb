pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Validate_Stack_Sequences; use Validate_Stack_Sequences;
procedure Tests is A : constant Sequence := [1, 2, 3, 4]; B : constant Sequence := [2, 1, 4, 3]; C : constant Sequence := [3, 1, 2, 4]; begin
   Assert (Valid (A, B, 4)); Assert (not Valid (A, C, 4)); Put_Line ("PASS Validate_Stack_Sequences");
end Tests;
