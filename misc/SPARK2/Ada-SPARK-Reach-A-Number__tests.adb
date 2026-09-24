with Ada.Assertions; use Ada.Assertions;
with Reach_A_Number; use Reach_A_Number;

procedure Tests is
begin
   Assert (Minimum_Steps (0) = 0);
   Assert (Minimum_Steps (2) = 3);
   Assert (Minimum_Steps (3) = 2);
   Assert (Minimum_Steps (-4) = 3);
   Assert (Minimum_Steps (100) = 15);
end Tests;
