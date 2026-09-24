with Cosine_Distance; use Cosine_Distance;
procedure Tests is
   A : constant Vector := [1, 2, 3];
   B : constant Vector := [1, 2, 3];
   C : constant Vector := [3, 2, 1];
   Empty : constant Vector := [0, 0, 0];
begin
   pragma Assert (Distance (A, A) = 0);
   pragma Assert (Distance (A, B) = 0);
   pragma Assert (Distance (A, C) = 490);
   pragma Assert (Distance (Empty, Empty) = 0);
end Tests;
