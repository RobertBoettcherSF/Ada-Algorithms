with Ada.Assertions; use Ada.Assertions;
with Bulb_Switcher; use Bulb_Switcher;

procedure Tests is
begin
   Assert (Switched_On (0) = 0);
   Assert (Switched_On (1) = 1);
   Assert (Switched_On (3) = 1);
   Assert (Switched_On (4) = 2);
   Assert (Switched_On (20) = 4);
end Tests;
