with Ada.Assertions; use Ada.Assertions;
with Permutations_II; use Permutations_II;
procedure Tests is
begin
   Assert (Count_Permutations (4, False) = 24);
   Assert (Count_Permutations (4, True) = 12);
   Assert (Count_Permutations (12, True) = 239_500_800);
end Tests;
