with Ada.Assertions; use Ada.Assertions;
with Four_Sum_II; use Four_Sum_II;

procedure Tests is
   Data : constant Values := (1, 0, -1, 0, -2, 2, others => 0);
begin
   Assert (Has_Four_Sum (Data, 6, 0));
   Assert (not Has_Four_Sum (Data, 6, 20));
end Tests;
