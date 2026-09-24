with Ada.Text_IO; use Ada.Text_IO;
with Prime_Check; use Prime_Check;

procedure Tests is
begin
   pragma Assert (Is_Prime (2));
   pragma Assert (Is_Prime (97));
   pragma Assert (not Is_Prime (91));
   Put_Line ("prime checks passed");
end Tests;
