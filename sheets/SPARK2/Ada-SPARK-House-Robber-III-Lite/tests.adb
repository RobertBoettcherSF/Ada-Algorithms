with House_Robber_III_Lite;
procedure Tests is
begin
   pragma Assert (House_Robber_III_Lite.Max_Loot (0) = 0);
   pragma Assert (House_Robber_III_Lite.Max_Loot (3) = 2);
   pragma Assert (House_Robber_III_Lite.Max_Loot (16) = 8);
end Tests;
