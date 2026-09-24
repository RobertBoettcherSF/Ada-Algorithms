with Ada.Assertions; use Ada.Assertions;
with Permutations; use Permutations;
procedure Tests is
begin
   Assert (Count_Permutations (0) = 1);
   Assert (Count_Permutations (5) = 120);
   Assert (Count_Permutations (12) = 479_001_600);
end Tests;
