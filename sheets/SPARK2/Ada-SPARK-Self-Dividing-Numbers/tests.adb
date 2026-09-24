with Ada.Assertions; use Ada.Assertions;
with Self_Dividing_Numbers; use Self_Dividing_Numbers;

procedure Tests is
begin
   Assert (Is_Self_Dividing (1));
   Assert (Is_Self_Dividing (128));
   Assert (not Is_Self_Dividing (26));
   Assert (not Is_Self_Dividing (101));
   Assert (Is_Self_Dividing (48));
end Tests;
