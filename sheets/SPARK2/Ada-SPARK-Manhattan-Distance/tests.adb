with Manhattan_Distance; use Manhattan_Distance;
procedure Tests is
   A : constant Vector := [-3, 4, -5];
   B : constant Vector := [4, -2, 1];
begin
   pragma Assert (Distance (A, A) = 0);
   pragma Assert (Distance (A, B) = 19);
   pragma Assert (Distance ([-10, -10, -10], [10, 10, 10]) = 60);
end Tests;
