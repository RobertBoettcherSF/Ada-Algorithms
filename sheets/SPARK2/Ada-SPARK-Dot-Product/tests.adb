with Dot_Product; use Dot_Product;
procedure Tests is
   A : constant Vector := [1, 2, 3];
   B : constant Vector := [4, -5, 6];
begin
   pragma Assert (Product (A, B) = 12);
   pragma Assert (Product (A, A) = 14);
   pragma Assert (Product ([0, 0, 0], B) = 0);
end Tests;
