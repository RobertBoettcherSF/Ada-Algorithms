with Ada.Assertions; use Ada.Assertions;
with Letter_Combinations_Of_A_Phone_Number;
use Letter_Combinations_Of_A_Phone_Number;
procedure Tests is
begin
   Assert (Count_Combinations (0) = 1);
   Assert (Count_Combinations (4) = 81);
   Assert (Count_Combinations (12) = 531_441);
end Tests;
