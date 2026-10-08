pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Coin_Change_II; use Coin_Change_II;
with Own_Checks;

procedure Tests is
   C : constant Coins := [1, 2, 3, 4];
begin
   Assert (Combinations (0, C, 4) = 1);
   Assert (Combinations (4, C, 4) = 5);
   Assert (Combinations (3, C, 2) = 2);
   Own_Checks;
end Tests;
