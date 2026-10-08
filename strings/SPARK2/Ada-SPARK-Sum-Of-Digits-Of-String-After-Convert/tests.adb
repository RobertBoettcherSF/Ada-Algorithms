with Ada.Assertions; use Ada.Assertions;
with Sum_Digits_Convert; use Sum_Digits_Convert;
with Own_Checks;

procedure Tests is
begin
   Assert (Sum_Digits (0) = 0);
   Assert (Sum_Digits (123) = 6);
   Assert (Sum_Digits (9_999) = 36);
   Own_Checks;
end Tests;
