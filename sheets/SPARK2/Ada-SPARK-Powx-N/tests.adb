with Ada.Assertions; use Ada.Assertions;
with Powx_N; use Powx_N;

procedure Tests is
begin
   Assert (Power_Of (7, 0) = 1);
   Assert (Power_Of (7, 1) = 7);
   Assert (Power_Of (7, 2) = 49);
   Assert (Power_Of (-10, 2) = 100);
end Tests;
