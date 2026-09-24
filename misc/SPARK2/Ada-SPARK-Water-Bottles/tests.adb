with Ada.Assertions; use Ada.Assertions;
with Water_Bottles; use Water_Bottles;
procedure Tests is
begin
   Assert (Total_Bottles (0, 3) = 0);
   Assert (Total_Bottles (9, 3) = 13);
   Assert (Total_Bottles (15, 4) = 19);
   Assert (Total_Bottles (100, 2) = 199);
end Tests;
