with Ada.Assertions; use Ada.Assertions;
with Integer_To_Roman; use Integer_To_Roman;

procedure Tests is
begin
   Assert (To_Roman (1) = "    I");
   Assert (To_Roman (4) = "   IV");
   Assert (To_Roman (9) = "   IX");
   Assert (To_Roman (10) = "    X");
end Tests;
