with UTF_8_Validation; use UTF_8_Validation;
procedure Tests is
begin
   pragma Assert (Is_ASCII (65));
   pragma Assert (not Is_ASCII (194));
end Tests;
