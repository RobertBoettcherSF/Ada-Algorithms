pragma Ada_2022;
with Line_Intersection;
procedure Tests is
   use Line_Intersection;
   A : constant Point := (0, 0);
   B : constant Point := (10, 10);
   C : constant Point := (0, 10);
   D : constant Point := (10, 0);
   E : constant Point := (0, 20);
   F : constant Point := (10, 20);
begin
   pragma Assert (Intersects (A, B, C, D));
   pragma Assert (not Intersects (A, B, E, F));
end Tests;
