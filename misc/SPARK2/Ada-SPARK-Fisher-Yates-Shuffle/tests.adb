pragma Ada_2022;
with Fisher_Yates_Shuffle;
procedure Tests is
   use Fisher_Yates_Shuffle;
   Data : Item_Array := [1, 2, 3, 4, 5, 6];
   Choices : constant Swap_Array := [1, 2, 3, 4, 5, 6];
begin
   Shuffle (Data, Choices);
   pragma Assert (Data = [1, 2, 3, 4, 5, 6]);
end Tests;
