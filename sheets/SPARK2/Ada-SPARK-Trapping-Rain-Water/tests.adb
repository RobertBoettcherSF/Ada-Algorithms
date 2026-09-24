with Ada.Assertions; use Ada.Assertions;
with Trapping_Rain_Water; use Trapping_Rain_Water;

procedure Tests is
   Data : Heights := (1 => 0, 2 => 1, 3 => 0, 4 => 2, 5 => 1, 6 => 0, 7 => 1, 8 => 3, 9 => 2, 10 => 1, 11 => 2, 12 => 1, others => 0);
begin
   Assert (Trapped (Data, 12) = 6);
   Assert (Trapped (Data, 1) = 0);
end Tests;
