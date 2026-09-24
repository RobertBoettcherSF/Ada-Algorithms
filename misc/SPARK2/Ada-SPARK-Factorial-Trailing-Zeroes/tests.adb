with Factorial_Trailing_Zeroes;
procedure Tests is
begin
   pragma Assert (Factorial_Trailing_Zeroes.Trailing_Zeroes (4) = 0);
   pragma Assert (Factorial_Trailing_Zeroes.Trailing_Zeroes (5) = 1);
   pragma Assert (Factorial_Trailing_Zeroes.Trailing_Zeroes (10) = 2);
end Tests;
