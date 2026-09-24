with Ada.Assertions; use Ada.Assertions;
with Authentication_Manager_Stub; use Authentication_Manager_Stub;
procedure Tests is
   Expires : Expiration_Array := (10, 20, 30, 40, others => 0);
begin
   Assert (Is_Valid (20, 10));
   Assert (not Is_Valid (20, 20));
   Assert (Count_Unexpired (Expires, 4, 25) = 2);
   Assert (Count_Unexpired (Expires, 0, 25) = 0);
end Tests;
