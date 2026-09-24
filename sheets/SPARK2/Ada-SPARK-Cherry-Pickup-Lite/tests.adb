with Cherry_Pickup_Lite;
procedure Tests is
begin
   pragma Assert (Cherry_Pickup_Lite.Max_Cherries (0) = 0);
   pragma Assert (Cherry_Pickup_Lite.Max_Cherries (8) = 8);
   pragma Assert (Cherry_Pickup_Lite.Max_Cherries (16) = 16);
end Tests;
