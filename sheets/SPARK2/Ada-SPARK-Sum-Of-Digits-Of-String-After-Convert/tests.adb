with Ada.Assertions; use Ada.Assertions;
with Sum_Digits_Convert; use Sum_Digits_Convert;

procedure Tests is
begin
   Assert (Sum_Digits (0) = 0);
   Assert (Sum_Digits (123) = 6);
   Assert (Sum_Digits (9_999) = 36);
end Tests;
