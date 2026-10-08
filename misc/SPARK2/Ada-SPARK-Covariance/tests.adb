with Covariance; use Covariance;
with Own_Checks;
procedure Tests is
   A : constant Vector := [0, 5, 10];
   B : constant Vector := [0, 5, 10];
   C : constant Vector := [10, 5, 0];
   Mid : constant Vector := [5, 5, 5];
begin
   Own_Checks;
   pragma Assert (Value (A, B) = 16);   --  (25 + 0 + 25) / 3 = 16.67, truncated
   pragma Assert (Value (A, C) = -16);
   pragma Assert (Value (A, Mid) = 0);
end Tests;
