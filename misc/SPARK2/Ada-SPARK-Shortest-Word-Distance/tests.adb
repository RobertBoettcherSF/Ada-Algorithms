with Ada.Assertions; use Ada.Assertions;
with Shortest_Word_Distance; use Shortest_Word_Distance;
with Own_Checks;
procedure Tests is
   Input : Text := [others => ' '];
   Result : Distance_Type;
begin
   Input (1 .. 7) := "abacaba";
   Minimum_Distance (Input, 7, 'a', 'b', Result);
   Assert (Result = 1);
   Minimum_Distance (Input, 7, 'x', 'y', Result);
   Assert (Result = 32);
   --  Hand-worked (agent A3): "b......a" puts the pair 7 apart either way
   --  round; a pair at the two ends of a full 32-character text is 31
   --  apart; a letter beyond Length does not count.
   Input := [others => ' '];
   Input (1 .. 8) := "b......a";
   Minimum_Distance (Input, 8, 'a', 'b', Result);
   Assert (Result = 7);
   Minimum_Distance (Input, 8, 'b', 'a', Result);
   Assert (Result = 7);
   Minimum_Distance (Input, 7, 'a', 'b', Result);
   Assert (Result = 32);
   Input := [others => '.'];
   Input (1) := 'x';
   Input (32) := 'y';
   Minimum_Distance (Input, 32, 'x', 'y', Result);
   Assert (Result = 31);
   Own_Checks;
end Tests;
