pragma Ada_2022;
with Duplicate_Zeros; use Duplicate_Zeros;
procedure Tests is
   Input : constant Int_Array := (1, 0, 2, 3, 0, 4, 5, 6);
   Output : Int_Array;
begin
   Duplicate (Input, Output);
   pragma Assert (Output = (1, 0, 0, 2, 3, 0, 0, 4));
end Tests;
