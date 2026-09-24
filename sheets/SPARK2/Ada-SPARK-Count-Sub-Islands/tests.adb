with Ada.Assertions; use Ada.Assertions;
with Count_Sub_Islands; use Count_Sub_Islands;
procedure Tests is
   Base : Grid := [others => [others => 0]];
   Candidate : Grid := [others => [others => 0]];
begin
   Base (1, 1) := 1;
   Base (2, 2) := 1;
   Candidate (1, 1) := 1;
   Candidate (1, 2) := 1;
   Assert (Count_Sub (Base, Candidate) = 1);
end Tests;
