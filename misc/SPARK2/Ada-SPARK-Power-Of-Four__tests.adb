with Ada.Assertions; use Ada.Assertions;
with Power_Of_Four; use Power_Of_Four;
procedure Tests is
begin
   Assert (Is_Power (1));
   Assert (Is_Power (4));
   Assert (Is_Power (64));
   Assert (not Is_Power (8));
   Assert (not Is_Power (12));
end Tests;
