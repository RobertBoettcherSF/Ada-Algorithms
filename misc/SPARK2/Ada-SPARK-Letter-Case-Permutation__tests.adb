with Ada.Assertions; use Ada.Assertions;
with Letter_Case_Permutation; use Letter_Case_Permutation;
procedure Tests is
begin
   Assert (Count_Permutations (0) = 1);
   Assert (Count_Permutations (3) = 8);
   Assert (Count_Permutations (12) = 4096);
end Tests;
