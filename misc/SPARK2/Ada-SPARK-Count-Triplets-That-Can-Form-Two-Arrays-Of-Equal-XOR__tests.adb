pragma Ada_2022;
with Count_Triplets_Equal_XOR;
procedure Tests is
   use Count_Triplets_Equal_XOR;
begin
   pragma Assert (Triplets ([1, 2, 3]) = 1);
   pragma Assert (Triplets ([1, 2, 4]) = 0);
end Tests;
