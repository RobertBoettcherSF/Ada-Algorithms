with L2_Norm_Squared; use L2_Norm_Squared;
procedure Tests is
   A : constant Vector := [-3, 4, -5];
begin
   pragma Assert (Norm_Squared ([0, 0, 0]) = 0);
   pragma Assert (Norm_Squared (A) = 50);
   pragma Assert (Norm_Squared ([10, 10, 10]) = 300);
end Tests;
