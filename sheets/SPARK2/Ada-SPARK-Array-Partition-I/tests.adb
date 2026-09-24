pragma Ada_2022;
with Array_Partition_I; use Array_Partition_I;
procedure Tests is
   Input : Int_Array := (1, 4, 3, 2, 2, 5, 6, 7);
begin
   Sort (Input);
   pragma Assert (Input = (1, 2, 2, 3, 4, 5, 6, 7));
   pragma Assert (Pair_Sum (Input) = 13);
end Tests;
