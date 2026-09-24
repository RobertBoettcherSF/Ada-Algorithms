with Covariance; use Covariance;
procedure Tests is
   A : constant Vector := [1, 2, 3];
   B : constant Vector := [1, 2, 3];
   C : constant Vector := [3, 2, 1];
   Mid : constant Vector := [5, 5, 5];
begin
   pragma Assert (Value (A, B) = 9);
   pragma Assert (Value (A, C) = 8);
   pragma Assert (Value (A, Mid) = 0);
end Tests;
