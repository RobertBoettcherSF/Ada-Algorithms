with Soup_Servings_Lite;
procedure Tests is
begin
   pragma Assert (Soup_Servings_Lite.First_Empties_First (0));
   pragma Assert (not Soup_Servings_Lite.First_Empties_First (1));
   pragma Assert (not Soup_Servings_Lite.First_Empties_First (16));
end Tests;
