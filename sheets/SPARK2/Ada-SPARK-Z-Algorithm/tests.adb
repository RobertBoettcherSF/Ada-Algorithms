pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Z_Algorithm; use Z_Algorithm;
procedure Tests is
   Text : constant Text_Array := "AABCAABX";
   Result : Z_Array;
begin
   Compute_Z (Text, Result);
   Assert (Result (1) = 0);
   Assert (Result (2) = 1);
   Assert (Result (5) = 3);
   Assert (Result (6) = 1);
   Put_Line ("PASS Z_Algorithm");
end Tests;
