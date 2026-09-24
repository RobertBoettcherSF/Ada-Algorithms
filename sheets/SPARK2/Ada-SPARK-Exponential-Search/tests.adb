pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Exponential_Search; use Exponential_Search;
procedure Tests is
   A : constant Data := [3, 7, 11, 18, 25, 31, 44, 90];
begin
   Assert (Search (A, 3) = 1);
   Assert (Search (A, 25) = 5);
   Assert (Search (A, 90) = 8);
   Assert (Search (A, 20) = 0);
   Put_Line ("PASS Exponential_Search");
end Tests;
