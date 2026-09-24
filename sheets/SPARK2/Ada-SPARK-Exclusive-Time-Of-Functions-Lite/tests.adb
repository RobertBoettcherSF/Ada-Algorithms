with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Exclusive_Time_Of_Functions_Lite; use Exclusive_Time_Of_Functions_Lite;
procedure Tests is begin
   Assert (Inclusive_Duration (2, 2) = 1); Assert (Inclusive_Duration (3, 7) = 5); Put_Line ("PASS Exclusive_Time_Of_Functions_Lite");
end Tests;
