with Ada.Assertions; use Ada.Assertions;
with Minimum_Number_Of_Moves_To_Seat; use Minimum_Number_Of_Moves_To_Seat;
procedure Tests is
begin
   Assert (Distance (3, 1) = 2);
   Assert (Distance (1, 3) = 2);
   Assert (Distance (0, 32) = 32);
end Tests;
