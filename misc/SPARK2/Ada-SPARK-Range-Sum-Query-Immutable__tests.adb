with Ada.Assertions; use Ada.Assertions;
with Range_Sum_Query_Immutable; use Range_Sum_Query_Immutable;

procedure Tests is
   A : Values := [others => 1];
begin
   Assert (Query (A, 1, 32) = 32);
   A (7) := 10;
   Assert (Query (A, 7, 7) = 10);
end Tests;
