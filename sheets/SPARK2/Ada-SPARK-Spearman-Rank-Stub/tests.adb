with Spearman_Rank_Stub; use Spearman_Rank_Stub;
procedure Tests is
   A : constant Vector := [1, 2, 3];
   B : constant Vector := [1, 2, 3];
   C : constant Vector := [3, 2, 1];
begin
   pragma Assert (Distance (A, A) = 0);
   pragma Assert (Distance (A, C) = 8);
end Tests;
