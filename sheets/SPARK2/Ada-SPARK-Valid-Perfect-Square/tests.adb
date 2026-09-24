with Valid_Perfect_Square;
procedure Tests is
begin
   pragma Assert (Valid_Perfect_Square.Is_Perfect_Square (0));
   pragma Assert (Valid_Perfect_Square.Is_Perfect_Square (49));
   pragma Assert (not Valid_Perfect_Square.Is_Perfect_Square (50));
   pragma Assert (Valid_Perfect_Square.Is_Perfect_Square (100));
end Tests;
