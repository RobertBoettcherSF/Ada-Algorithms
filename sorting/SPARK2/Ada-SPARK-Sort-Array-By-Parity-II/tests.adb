pragma Ada_2022;
with Sort_Array_By_Parity_II; use Sort_Array_By_Parity_II;
procedure Tests is
   Input : constant Int_Array := (4, 2, 5, 7, 8, 1, 6, 3);
   Output : Int_Array;
begin
   Sort_By_Parity (Input, Output);
   pragma Assert (Output = (5, 4, 7, 2, 1, 8, 3, 6));
end Tests;
