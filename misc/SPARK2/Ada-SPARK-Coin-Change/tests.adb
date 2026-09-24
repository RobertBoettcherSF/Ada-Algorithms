with Coin_Change;
procedure Tests is
begin
   pragma Assert (Coin_Change.Minimum (0) = 0);
   pragma Assert (Coin_Change.Minimum (3) = 2);
   pragma Assert (Coin_Change.Minimum (6) = 2);
   pragma Assert (Coin_Change.Minimum (9) = 3);
   pragma Assert (Coin_Change.Minimum (10) = 2);
end Tests;
