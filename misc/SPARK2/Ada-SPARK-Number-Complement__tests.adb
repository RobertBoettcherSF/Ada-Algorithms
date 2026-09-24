with Number_Complement; use Number_Complement;
procedure Tests is
begin
   pragma Assert (Complement (0) = 255);
   pragma Assert (Complement (170) = 85);
end Tests;
