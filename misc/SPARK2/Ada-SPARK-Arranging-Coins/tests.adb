with Ada.Assertions; use Ada.Assertions;
with Arranging_Coins; use Arranging_Coins;

procedure Tests is
begin
   Assert (Full_Rows (0) = 0);
   Assert (Full_Rows (1) = 1);
   Assert (Full_Rows (3) = 2);
   Assert (Full_Rows (5) = 2);
   Assert (Full_Rows (8) = 3);
   Assert (Full_Rows (1_000_000_000) = 44_720);
end Tests;
