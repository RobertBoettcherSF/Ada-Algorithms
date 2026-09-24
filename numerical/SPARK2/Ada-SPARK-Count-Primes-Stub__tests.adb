with Ada.Assertions; use Ada.Assertions;
with Count_Primes; use Count_Primes;
procedure Tests is
begin
   Assert (Below (0) = 0);
   Assert (Below (2) = 0);
   Assert (Below (10) = 4);
   Assert (Below (100) = 25);
end Tests;
