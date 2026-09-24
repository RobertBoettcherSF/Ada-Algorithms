pragma Ada_2022;
with Sparse_Dot;
procedure Tests is
   use Sparse_Dot;
   Values : constant Sparse_Values := [2, -1, 3];
   Indices : constant Sparse_Indices := [1, 3, 5];
   Dense : constant Dense_Vector := [4, 7, -2, 1, 5];
begin
   pragma Assert (Dot (Values, Indices, Dense) = 25);
end Tests;
