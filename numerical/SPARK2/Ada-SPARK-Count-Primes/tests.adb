with Count_Primes; use Count_Primes;
with Own_Checks;
procedure Tests with SPARK_Mode => Off is
begin
   pragma Assert (Count_Primes_Below (0) = 0);
   pragma Assert (Count_Primes_Below (10) = 4);
   pragma Assert (Count_Primes_Below (30) = 10);
   Own_Checks;
end Tests;
