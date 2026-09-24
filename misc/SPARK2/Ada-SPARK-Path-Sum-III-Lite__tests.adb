with Ada.Assertions; use Ada.Assertions;
with Path_Sum_III_Lite; use Path_Sum_III_Lite;

procedure Tests is
   A : Nodes := [others => 1];
begin
   Assert (Path_Total (A) = 32);
   A (5) := 10;
   Assert (Path_Total (A) = 41);
end Tests;
