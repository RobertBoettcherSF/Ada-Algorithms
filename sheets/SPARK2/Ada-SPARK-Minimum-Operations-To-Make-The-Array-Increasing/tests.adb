with Ada.Assertions; use Ada.Assertions;
with Minimum_Operations_To_Make_Increasing;
use Minimum_Operations_To_Make_Increasing;
procedure Tests is
begin
   Assert (Required_Increase (1, 3) = 0);
   Assert (Required_Increase (3, 3) = 1);
   Assert (Required_Increase (5, 2) = 4);
end Tests;
