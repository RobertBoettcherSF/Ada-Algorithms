with Ada.Assertions; use Ada.Assertions;
with Smallest_Integer_Divisible_By_K; use Smallest_Integer_Divisible_By_K;

procedure Tests is
begin
   Assert (Smallest_Length (1) = 1);
   Assert (Smallest_Length (2) = 0);
   Assert (Smallest_Length (3) = 3);
   Assert (Smallest_Length (7) = 6);
   Assert (Smallest_Length (9) = 9);
end Tests;
