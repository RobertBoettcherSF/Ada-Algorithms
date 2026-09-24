pragma Ada_2022;
with Convert_A_Number_To_Hexadecimal;
procedure Tests is
   package H renames Convert_A_Number_To_Hexadecimal;
begin
   pragma Assert (H.Digit (0) = '0');
   pragma Assert (H.Digit (9) = '9');
   pragma Assert (H.Digit (10) = 'A');
   pragma Assert (H.Digit (15) = 'F');
end Tests;
