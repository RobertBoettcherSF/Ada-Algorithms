with Canberra_Distance; use Canberra_Distance;
procedure Tests is
   A : constant Vector := [1, 2, 3];
   B : constant Vector := [1, 2, 3];
   C : constant Vector := [2, 4, 6];
   Empty : constant Vector := [0, 0, 0];
begin
   pragma Assert (Distance (A, B) = 0);
   pragma Assert (Distance (A, C) = 999);
   pragma Assert (Distance (Empty, Empty) = 0);
end Tests;
