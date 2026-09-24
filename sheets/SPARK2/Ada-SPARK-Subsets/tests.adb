with Ada.Assertions; use Ada.Assertions;
with Subsets; use Subsets;
procedure Tests is
begin
   Assert (Count_Subsets (0) = 1);
   Assert (Count_Subsets (5) = 32);
   Assert (Count_Subsets (12) = 4_096);
end Tests;
