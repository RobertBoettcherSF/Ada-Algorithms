with Overlap_Coefficient; use Overlap_Coefficient;
procedure Tests is
   A : constant Vector := [1, 2, 3];
   B : constant Vector := [1, 1, 4];
   C : constant Vector := [2, 4, 6];
   Empty : constant Vector := [0, 0, 0];
begin
   pragma Assert (Similarity (A, A) = 100);
   pragma Assert (Similarity (A, B) = 83);
   pragma Assert (Similarity (A, C) = 100);
   pragma Assert (Similarity (Empty, Empty) = 100);
end Tests;
