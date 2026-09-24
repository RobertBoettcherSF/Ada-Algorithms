with Dice_Coefficient; use Dice_Coefficient;
procedure Tests is
   A : constant Vector := [1, 1, 0];
   B : constant Vector := [1, 0, 1];
   Empty : constant Vector := [0, 0, 0];
begin
   pragma Assert (Similarity (A, A) = 100);
   pragma Assert (Similarity (A, B) = 50);
   pragma Assert (Similarity (A, Empty) = 0);
   pragma Assert (Similarity (Empty, Empty) = 100);
end Tests;
