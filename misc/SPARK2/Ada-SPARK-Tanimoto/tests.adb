with Tanimoto; use Tanimoto;
procedure Tests is
   A : constant Vector := [1, 2, 3];
   B : constant Vector := [1, 1, 2];
   Empty : constant Vector := [0, 0, 0];
begin
   pragma Assert (Similarity (A, A) = 100);
   pragma Assert (Similarity (A, B) = 81);
   pragma Assert (Similarity (Empty, Empty) = 100);
end Tests;
