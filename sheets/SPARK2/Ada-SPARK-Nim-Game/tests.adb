with Ada.Assertions; use Ada.Assertions;
with Nim_Game; use Nim_Game;

procedure Tests is
begin
   Assert (not Winning_Position (0));
   Assert (Winning_Position (1));
   Assert (Winning_Position (2));
   Assert (Winning_Position (3));
   Assert (not Winning_Position (4));
   Assert (not Winning_Position (1_000_000_000));
end Tests;
