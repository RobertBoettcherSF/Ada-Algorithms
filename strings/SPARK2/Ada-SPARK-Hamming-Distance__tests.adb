with Hamming_Distance; use Hamming_Distance;
procedure Tests is
   A : constant Vector := [0, 1, 0];
   B : constant Vector := [1, 1, 0];
   C : constant Vector := [0, 1, 0];
begin
   pragma Assert (Distance (A, A) = 0);
   pragma Assert (Distance (A, B) = 1);
   pragma Assert (Distance (A, [1, 0, 1]) = 3);
   pragma Assert (Distance (A, C) = 0);
end Tests;
