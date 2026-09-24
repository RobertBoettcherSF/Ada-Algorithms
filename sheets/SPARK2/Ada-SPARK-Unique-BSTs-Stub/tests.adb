with Ada.Assertions; use Ada.Assertions; with Ada.Text_IO; use Ada.Text_IO;
with Unique_BSTs_Stub; use Unique_BSTs_Stub;
procedure Tests is begin
   Assert (Number_Of_Trees (0) = 1); Assert (Number_Of_Trees (3) = 5); Assert (Number_Of_Trees (5) = 42);
   Put_Line ("PASS Unique_BSTs_Stub");
end Tests;
