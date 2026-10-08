pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Unique_BSTs_Stub; use Unique_BSTs_Stub;
procedure Tests is
begin
   Assert (Number_Of_Trees (0) = 1);
   Assert (Number_Of_Trees (1) = 1);
   Assert (Number_Of_Trees (2) = 2);
   Assert (Number_Of_Trees (3) = 5);
   Assert (Number_Of_Trees (4) = 14);
   Assert (Number_Of_Trees (5) = 42);
   Assert (Number_Of_Trees (6) = 132);
   Assert (Number_Of_Trees (7) = 429);
   Assert (Number_Of_Trees (8) = 1430);
   Put_Line ("PASS Unique_BSTs_Stub");
end Tests;
