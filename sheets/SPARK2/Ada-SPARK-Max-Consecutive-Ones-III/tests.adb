pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Max_Consecutive_Ones_III; use Max_Consecutive_Ones_III;
procedure Tests is
begin
   Assert (Longest ([1, 1, 1, 0, 0, 0, 1, 1]) = 5);
   Assert (Longest ([0, 0, 0, 0, 0, 0, 0, 0]) = 2);
   Assert (Longest ([1, 1, 1, 1, 1, 1, 1, 1]) = 8);
end Tests;
