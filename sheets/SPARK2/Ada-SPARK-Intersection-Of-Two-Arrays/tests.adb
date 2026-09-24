with Ada.Assertions; use Ada.Assertions;
with Intersection_Of_Two_Arrays; use Intersection_Of_Two_Arrays;

procedure Tests is
   Left : Values := (1 => 1, 2 => 2, 3 => 2, 4 => 4, others => -999);
   Right : Values := (1 => 2, 2 => 4, 3 => 6, others => 999);
begin
   Assert (Count (Left, Right) = 3);
end Tests;
