with Ada.Assertions; use Ada.Assertions;
with Subsets_II; use Subsets_II;
procedure Tests is
begin
   Assert (Count_Distinct_Subsets (0) = 1);
   Assert (Count_Distinct_Subsets (6) = 64);
   Assert (Count_Distinct_Subsets (12) = 4_096);
end Tests;
