pragma Ada_2022;
with Relative_Sort_Array; use Relative_Sort_Array;
procedure Tests is
   Input : constant Int_Array := (2, 3, 1, 3, 2, 4, 6, 7);
   Pattern : constant Pattern_Array := (3, 2, 1, 4);
   Output : Int_Array;
begin
   Relative_Sort (Input, Pattern, Output);
   pragma Assert (Output = (3, 3, 2, 2, 1, 4, 6, 7));
end Tests;
