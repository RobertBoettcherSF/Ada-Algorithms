pragma Ada_2022;
with Move_To_Front;
procedure Tests is
   use Move_To_Front;
   Values : Table := ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h',
                      'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p'];
begin
   Move (Values, 4);
   pragma Assert (Values (1) = 'd');
   pragma Assert (Values (2) = 'a');
   pragma Assert (Values (4) = 'c');
   Move (Values, 1);
   pragma Assert (Values (1) = 'd');
end Tests;
