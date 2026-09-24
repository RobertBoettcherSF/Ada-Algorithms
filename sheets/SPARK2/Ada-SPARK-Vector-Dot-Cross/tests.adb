pragma Ada_2022;
with Vector_Dot_Cross;
procedure Tests is
   A : constant Vector_Dot_Cross.Vector := (3, 4);
   B : constant Vector_Dot_Cross.Vector := (-2, 5);
begin
   pragma Assert (Vector_Dot_Cross.Dot (A, B) = 14);
   pragma Assert (Vector_Dot_Cross.Cross (A, B) = 23);
end Tests;
