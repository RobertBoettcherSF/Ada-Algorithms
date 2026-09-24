with Ada.Assertions; use Ada.Assertions;
with Hamming_Weight; use Hamming_Weight;

procedure Tests is
begin
   Assert (Weight (0) = 0);
   Assert (Weight (7) = 3);
   Assert (Weight (16#8000#) = 1);
   Assert (Weight (1_000_000_000) = 13);
end Tests;
