with Ada.Assertions; use Ada.Assertions;
with Find_The_Smallest_Divisor; use Find_The_Smallest_Divisor;

procedure Tests is
   Values : constant Value_Array := [1, 2, 5, 9, 10, 11, 15, 20];
begin
   Assert (Smallest_Divisor (Values, 8) = 20);
   Assert (Smallest_Divisor (Values, 20) = 5);
end Tests;
