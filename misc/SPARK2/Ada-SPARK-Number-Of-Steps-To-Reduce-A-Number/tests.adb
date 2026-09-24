with Ada.Assertions; use Ada.Assertions;
with Number_Of_Steps; use Number_Of_Steps;

procedure Tests is
begin
   Assert (Steps_To_Zero (0) = 0);
   Assert (Steps_To_Zero (1) = 1);
   Assert (Steps_To_Zero (14) = 6);
   Assert (Steps_To_Zero (8) = 4);
end Tests;
