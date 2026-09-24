with Ada.Assertions; use Ada.Assertions;
with Bitwise_AND_Of_Numbers_Range; use Bitwise_AND_Of_Numbers_Range;
procedure Tests is
begin
   Assert (And_Range (3, 3) = 3);
   Assert (And_Range (5, 7) = 4);
   Assert (And_Range (10, 12) = 8);
end Tests;
