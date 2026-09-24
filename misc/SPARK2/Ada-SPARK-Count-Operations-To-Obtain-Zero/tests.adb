with Ada.Assertions; use Ada.Assertions;
with Count_Operations_To_Obtain_Zero;
use Count_Operations_To_Obtain_Zero;
procedure Tests is
begin
   Assert (Operations (2, 3) = 3);
   Assert (Operations (10, 10) = 1);
   Assert (Operations (0, 7) = 0);
end Tests;
