with Pow_X_N; use Pow_X_N;
procedure Tests with SPARK_Mode => Off is
begin
   pragma Assert (Power (2, 5) = 32);
   pragma Assert (Power (-2, 3) = -8);
   pragma Assert (Power (0, 0) = 1);
end Tests;
