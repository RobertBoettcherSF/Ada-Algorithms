with Ada.Assertions; use Ada.Assertions;
with Add_Digits; use Add_Digits;

procedure Tests is
begin
   Assert (Digital_Root (0) = 0);
   Assert (Digital_Root (38) = 2);
   Assert (Digital_Root (9) = 9);
   Assert (Digital_Root (99) = 9);
   Assert (Digital_Root (1_000_000_000) = 1);
end Tests;
