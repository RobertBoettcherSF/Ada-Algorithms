with New_21_Game_Lite;
procedure Tests is
begin
   pragma Assert (New_21_Game_Lite.Target_Is_Reachable (0));
   pragma Assert (New_21_Game_Lite.Target_Is_Reachable (10));
   pragma Assert (not New_21_Game_Lite.Target_Is_Reachable (16));
end Tests;
