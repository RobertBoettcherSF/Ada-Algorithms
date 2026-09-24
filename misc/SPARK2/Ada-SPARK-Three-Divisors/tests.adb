with Ada.Assertions; use Ada.Assertions;
with Three_Divisors; use Three_Divisors;

procedure Tests is
begin
   Assert (not Has_Three_Divisors (1));
   Assert (Has_Three_Divisors (4));
   Assert (Has_Three_Divisors (9));
   Assert (not Has_Three_Divisors (16));
   Assert (not Has_Three_Divisors (12));
end Tests;
