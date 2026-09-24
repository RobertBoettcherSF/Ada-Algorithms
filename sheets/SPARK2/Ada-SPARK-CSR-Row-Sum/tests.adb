pragma Ada_2022;
with CSR_Row_Sum;
procedure Tests is
   use CSR_Row_Sum;
   Values : constant Value_Array := [1, 2, 3, 4, 5, 6];
begin
   pragma Assert (Row_Sum (Values, 1) = 3);
   pragma Assert (Row_Sum (Values, 2) = 7);
   pragma Assert (Row_Sum (Values, 3) = 11);
end Tests;
