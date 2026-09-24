with Ada.Assertions; use Ada.Assertions;
with Four_Sum; use Four_Sum;

procedure Tests is
   Data : Values := (1 => 1, 2 => 0, 3 => -1, 4 => 0, others => 0);
begin
   Assert (Has_Four_Sum (Data, 4, 0));
   Assert (not Has_Four_Sum (Data, 3, 5));
end Tests;
