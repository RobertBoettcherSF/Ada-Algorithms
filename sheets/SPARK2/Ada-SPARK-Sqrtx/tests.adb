with Ada.Assertions; use Ada.Assertions;
with Sqrtx; use Sqrtx;

procedure Tests is
begin
   Assert (Integer_Square_Root (0) = 0);
   Assert (Integer_Square_Root (1) = 1);
   Assert (Integer_Square_Root (8) = 2);
   Assert (Integer_Square_Root (10_000) = 100);
end Tests;
