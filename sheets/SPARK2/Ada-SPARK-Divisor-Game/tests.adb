with Divisor_Game;
procedure Tests is
begin
   pragma Assert (Divisor_Game.Alice_Wins (1) = False);
   pragma Assert (Divisor_Game.Alice_Wins (2));
   pragma Assert (Divisor_Game.Alice_Wins (16));
end Tests;
