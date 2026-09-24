with Ada.Assertions; use Ada.Assertions;
with Count_Odd_Numbers; use Count_Odd_Numbers;

procedure Tests is
begin
   Assert (Count (1, 1) = 1);
   Assert (Count (1, 10) = 5);
   Assert (Count (2, 10) = 4);
   Assert (Count (0, 1_000_000_000) = 500_000_000);
end Tests;
