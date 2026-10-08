with Linear_Regression; use Linear_Regression;
with Own_Checks;
procedure Tests is
begin
   pragma Assert (Predict (2, 4, 6, 8, 4) = 8);
   pragma Assert (Predict (8, 6, 4, 2, 1) = 8);
   pragma Assert (Predict (5, 5, 5, 5, 3) = 5);
   Own_Checks;
end Tests;
