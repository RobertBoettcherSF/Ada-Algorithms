with Ada.Assertions; use Ada.Assertions;
with Magnetic_Force_Between_Two_Balls;
use Magnetic_Force_Between_Two_Balls;

procedure Tests is
   Positions : constant Position_Array := [1, 2, 4, 8, 16, 20, 24, 32];
begin
   Assert (Maximum_Force (Positions) = 31);
end Tests;
