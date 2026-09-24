with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Guess_Number_Higher_Or_Lower; use Guess_Number_Higher_Or_Lower;

procedure Tests is
begin
   Assert (Guess_Number (23) = 23);
   Assert (Guess_Number (1) = 1);
   Put_Line ("PASS Guess_Number_Higher_Or_Lower");
end Tests;
