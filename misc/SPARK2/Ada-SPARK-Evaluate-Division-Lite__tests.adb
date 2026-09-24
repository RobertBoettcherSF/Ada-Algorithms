with Ada.Assertions; use Ada.Assertions;
with Evaluate_Division_Lite; use Evaluate_Division_Lite;
procedure Tests is
   T : Relations := [others => [others => 0]];
begin
   T (1, 2) := 2;
   Assert (Evaluate (T, 1, 2) = 2);
   Assert (Evaluate (T, 1, 1) = 1);
end Tests;
