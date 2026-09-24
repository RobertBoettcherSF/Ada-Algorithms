with Euclidean_Distance; use Euclidean_Distance;
procedure Tests is
   A : constant Point := (0, 0);
   B : constant Point := (3, 4);
begin
   pragma Assert (Distance (A, A) = 0);
   pragma Assert (Distance (A, B) = 25);
end Tests;
