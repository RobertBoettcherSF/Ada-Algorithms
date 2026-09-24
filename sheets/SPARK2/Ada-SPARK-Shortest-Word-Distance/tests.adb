with Ada.Assertions; use Ada.Assertions;
with Shortest_Word_Distance; use Shortest_Word_Distance;
procedure Tests is
   Input : Text := (others => ' ');
   Result : Distance_Type;
begin
   Input (1 .. 7) := "abacaba";
   Minimum_Distance (Input, 7, 'a', 'b', Result);
   Assert (Result = 1);
   Minimum_Distance (Input, 7, 'x', 'y', Result);
   Assert (Result = 32);
end Tests;
