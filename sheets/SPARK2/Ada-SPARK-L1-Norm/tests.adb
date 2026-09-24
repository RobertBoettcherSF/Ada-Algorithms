with L1_Norm; use L1_Norm;
procedure Tests is
   A : constant Vector := [-3, 4, -5];
begin
   pragma Assert (Norm ([0, 0, 0]) = 0);
   pragma Assert (Norm (A) = 12);
   pragma Assert (Norm ([-10, -10, -10]) = 30);
end Tests;
