with Jaccard_Index; use Jaccard_Index;
procedure Tests is
   A : constant Vector := [1, 1, 0];
   B : constant Vector := [1, 0, 1];
   Empty : constant Vector := [0, 0, 0];
begin
   pragma Assert (Similarity (A, A) = 100);
   pragma Assert (Similarity (A, B) = 33);
   pragma Assert (Similarity (A, Empty) = 0);
   pragma Assert (Similarity (Empty, Empty) = 100);
end Tests;
