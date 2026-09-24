with Ada.Assertions; use Ada.Assertions;
with Target_Sum; use Target_Sum;

procedure Tests is
   A : Values := (1, 1, 1, 1);
begin
   Assert (Ways_To_Target (A, 4, 2) = 4);
   Assert (Ways_To_Target (A, 4, 0) = 6);
   Assert (Ways_To_Target (A, 0, 0) = 1);
end Tests;
