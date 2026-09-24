pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Number_Of_Provinces; use Number_Of_Provinces;
procedure Tests is
   M : Connection_Matrix := [others => [others => False]];
begin
   M (1, 1) := True; M (3, 3) := True; M (5, 5) := True;
   Assert (Count_Provinces (M) = 3);
end Tests;
