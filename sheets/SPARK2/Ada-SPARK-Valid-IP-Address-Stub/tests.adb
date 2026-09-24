with Ada.Assertions; use Ada.Assertions;
with Valid_IP_Address_Stub; use Valid_IP_Address_Stub;

procedure Tests is
   Localhost : constant Address := (127, 0, 0, 1);
   Public : constant Address := (192, 168, 1, 10);
begin
   Assert (Is_Valid (Localhost));
   Assert (Is_Valid (Public));
   Assert (Is_Loopback (Localhost));
   Assert (not Is_Loopback (Public));
end Tests;
