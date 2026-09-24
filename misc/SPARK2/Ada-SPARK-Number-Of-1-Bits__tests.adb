with Ada.Assertions; use Ada.Assertions;
with Number_Of_1_Bits; use Number_Of_1_Bits;

procedure Tests is
begin
   Assert (Count_Ones (0) = 0);
   Assert (Count_Ones (3) = 2);
   Assert (Count_Ones (16#FFFF#) = 16);
   Assert (Count_Ones (1_000_000_000) = 13);
end Tests;
