with Pearson_Correlation; use Pearson_Correlation;
procedure Tests is
   A : constant Vector := [1, 2, 3];
   B : constant Vector := [9, 8, 7];
   C : constant Vector := [3, 2, 1];
   Mid : constant Vector := [5, 5, 5];
begin
   pragma Assert (Correlation (A, A) = 29);
   pragma Assert (Correlation (A, B) = -29);
   pragma Assert (Correlation (A, C) = 25);
   pragma Assert (Correlation (Mid, Mid) = 100);
end Tests;
