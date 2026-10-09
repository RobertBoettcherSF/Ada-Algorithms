with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO;
with Count_Operations_To_Obtain_Zero;
use Count_Operations_To_Obtain_Zero;
with Own_Checks;
procedure Tests is
begin
   Assert (Operations (2, 3) = 3);
   Assert (Operations (10, 10) = 1);
   Assert (Operations (0, 7) = 0);
   --  Hand-worked (V&V sweep, agent A3; tests/SOURCES.txt).
   Assert (Operations (7, 0) = 0);
   Assert (Operations (0, 0) = 0);
   Assert (Operations (1, 1) = 1);
   Assert (Operations (5, 3) = 4);
   Assert (Operations (3, 5) = 4);
   Assert (Operations (1, 32) = 32);
   Assert (Operations (32, 1) = 32);
   Assert (Operations (32, 32) = 1);
   Assert (Operations (31, 32) = 32);
   Assert (Operations (12, 18) = 3);
   Assert (Operations (21, 13) = 7);
   Own_Checks;
   Ada.Text_IO.Put_Line ("PASS Count_Operations_To_Obtain_Zero");
end Tests;
