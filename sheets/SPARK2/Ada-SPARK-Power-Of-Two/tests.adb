with Ada.Assertions; use Ada.Assertions;
with Power_Of_Two; use Power_Of_Two;

procedure Tests is
begin
   Assert (Is_Power (1));
   Assert (Is_Power (2));
   Assert (Is_Power (1024));
   Assert (not Is_Power (12));
   Assert (not Is_Power (1023));
end Tests;
