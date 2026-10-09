with Ada.Assertions; use Ada.Assertions;
with Reach_A_Number; use Reach_A_Number;
with Own_Checks;

procedure Tests is
begin
   Assert (Minimum_Steps (0) = 0);
   Assert (Minimum_Steps (2) = 3);
   Assert (Minimum_Steps (3) = 2);
   Assert (Minimum_Steps (-4) = 3);
   Assert (Minimum_Steps (100) = 15);
   --  Hand-worked (agent A3): 1 = +1; -1 = -1; for 5, the sums 1+2+3 = 6,
   --  1+..+4 = 10 overshoot by 1 and 5 (odd, no flip fixes them), 1+..+5 =
   --  15 overshoots by 10 = 2 * 5, so 1+2+3+4-5 = 5 in 5 moves; 6 = 1+2+3;
   --  -100 is the mirror of 100.
   Assert (Minimum_Steps (1) = 1);
   Assert (Minimum_Steps (-1) = 1);
   Assert (Minimum_Steps (5) = 5);
   Assert (Minimum_Steps (6) = 3);
   Assert (Minimum_Steps (-100) = 15);
   Own_Checks;
end Tests;
