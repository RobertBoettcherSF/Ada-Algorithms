pragma Ada_2022;
with Fair_Candy_Swap; use Fair_Candy_Swap;
procedure Tests is
   Alice : constant Candy_Array := (1, 1, 3, 5);
   Bob : constant Candy_Array := (2, 2, 2, 2);
   Swap_A : Candy; Swap_B : Candy; Found : Boolean;
begin
   Find_Swap (Alice, Bob, Swap_A, Swap_B, Found);
   pragma Assert (Found);
   pragma Assert (Swap_A = 3 and then Swap_B = 2);
end Tests;
