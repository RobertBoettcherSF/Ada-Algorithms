with Ada.Assertions; use Ada.Assertions;
with Nth_Digit; use Nth_Digit;

procedure Tests is
begin
   Assert (Digit_At (0) = 1);
   Assert (Digit_At (8) = 9);
   Assert (Digit_At (9) = 1);
end Tests;
