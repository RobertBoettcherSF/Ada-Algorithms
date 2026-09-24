with Ada.Assertions; use Ada.Assertions;
with Minimum_Cost_To_Move_Chips; use Minimum_Cost_To_Move_Chips;
procedure Tests is
begin
   Assert (Cost_To_Target (2, 4) = 0);
   Assert (Cost_To_Target (1, 4) = 1);
   Assert (Cost_To_Target (31, 1) = 0);
end Tests;
