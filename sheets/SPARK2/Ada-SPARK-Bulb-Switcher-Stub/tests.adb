with Ada.Assertions; use Ada.Assertions;
with Bulb_Switcher_Stub; use Bulb_Switcher_Stub;

procedure Tests is
begin
   Assert (On_Count (0) = 0);
   Assert (On_Count (1) = 1);
   Assert (On_Count (3) = 1);
   Assert (On_Count (4) = 2);
   Assert (On_Count (8) = 2);
   Assert (On_Count (1_000_000_000) = 31_622);
end Tests;
