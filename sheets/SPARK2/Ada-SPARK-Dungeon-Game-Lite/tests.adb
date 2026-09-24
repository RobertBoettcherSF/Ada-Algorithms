with Dungeon_Game_Lite;
procedure Tests is
begin
   pragma Assert (Dungeon_Game_Lite.Required_Health (1, 1) = 1);
   pragma Assert (Dungeon_Game_Lite.Required_Health (4, 7) = 1);
   pragma Assert (Dungeon_Game_Lite.Required_Health (16, 16) = 1);
end Tests;
