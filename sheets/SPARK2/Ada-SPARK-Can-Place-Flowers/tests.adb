with Can_Place_Flowers;
procedure Tests is
begin
   pragma Assert (Can_Place_Flowers.Can_Place (3, 2));
   pragma Assert (Can_Place_Flowers.Can_Place (0, 0));
   pragma Assert (not Can_Place_Flowers.Can_Place (1, 2));
end Tests;
