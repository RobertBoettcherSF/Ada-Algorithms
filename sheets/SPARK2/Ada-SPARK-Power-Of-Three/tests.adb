with Ada.Assertions; use Ada.Assertions;
with Power_Of_Three; use Power_Of_Three;

procedure Tests is
begin
   Assert (Is_Power (1));
   Assert (Is_Power (3));
   Assert (Is_Power (729));
   Assert (not Is_Power (12));
   Assert (not Is_Power (728));
end Tests;
