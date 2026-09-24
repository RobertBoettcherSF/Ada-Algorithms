pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Kadanes_Algorithm; use Kadanes_Algorithm;
procedure Tests is
   A : constant Input := [ -2, 3, -1, 4 ];
   B : constant Input := [ -5, -2, -7, -1 ];
begin
   Assert (Maximum_Subarray (A) = 6);
   Assert (Maximum_Subarray (B) = -1);
   Put_Line ("PASS Kadanes_Algorithm");
end Tests;
