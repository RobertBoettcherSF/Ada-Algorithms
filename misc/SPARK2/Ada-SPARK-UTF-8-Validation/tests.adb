pragma Ada_2022;
with UTF_8_Validation; use UTF_8_Validation;
procedure Tests is
begin
   pragma Assert (Is_ASCII (65));
   pragma Assert (Is_ASCII (0));
   pragma Assert (Is_ASCII (127));
   pragma Assert (not Is_ASCII (128));
   pragma Assert (not Is_ASCII (194));
   pragma Assert (not Is_ASCII (255));
end Tests;
