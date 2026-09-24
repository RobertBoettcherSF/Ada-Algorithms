with Multiply_Strings_Lite;
procedure Tests is
begin
   pragma Assert (Multiply_Strings_Lite.Multiply (0, 9) = 0);
   pragma Assert (Multiply_Strings_Lite.Multiply (7, 8) = 56);
   pragma Assert (Multiply_Strings_Lite.Multiply (9, 9) = 81);
end Tests;
