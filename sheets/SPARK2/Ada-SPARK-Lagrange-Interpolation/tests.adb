with Lagrange_Interpolation; use Lagrange_Interpolation;
procedure Tests is
begin
   pragma Assert (Interpolate (1, 0, 1, 0) = 0);
   pragma Assert (Interpolate (0, 1, 4, 1) = 4);
   pragma Assert (Interpolate (1, 3, 5, -1) = 1);
end Tests;
