pragma Ada_2022;
with Binary_To_Integer;
with Interfaces;
procedure Tests is
   use type Interfaces.Unsigned_32;
   package B renames Binary_To_Integer;
begin
   pragma Assert (B.From_Binary_Nibble (0, 0, 0, 0) = 0);
   pragma Assert (B.From_Binary_Nibble (1, 0, 1, 0) = 10);
   pragma Assert (B.From_Binary_Nibble (1, 1, 1, 1) = 15);
end Tests;
