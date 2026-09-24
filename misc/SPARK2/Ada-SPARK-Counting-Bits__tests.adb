with Ada.Assertions; use Ada.Assertions;
with Counting_Bits; use Counting_Bits;

procedure Tests is
begin
   Assert (Ones (0) = 0);
   Assert (Ones (1) = 1);
   Assert (Ones (15) = 4);
   Assert (Ones (255) = 8);
   Assert (Ones (1_000_000_000) = 13);
end Tests;
