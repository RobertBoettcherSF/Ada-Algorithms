pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Fisher_Yates_Shuffle;
procedure Tests is
   use Fisher_Yates_Shuffle;
   Data : Item_Array := [1, 2, 3, 4, 5, 6];
begin
   --  Identity choices leave the array as it is.
   Shuffle (Data, [1, 2, 3, 4, 5, 6]);
   pragma Assert (Data = [1, 2, 3, 4, 5, 6]);
   --  I = 6 swaps with 1, 5 with 2, 4 with 4, 3 with 1, 2 with 1:
   --  [1,2,3,4,5,6] -> [6,2,3,4,5,1] -> [6,5,3,4,2,1] -> (4 stays)
   --  -> [3,5,6,4,2,1] -> [5,3,6,4,2,1].
   Shuffle (Data, [1, 1, 1, 4, 2, 1]);
   pragma Assert (Data = [5, 3, 6, 4, 2, 1]);
   Put_Line ("Fisher_Yates_Shuffle: PASS");
end Tests;
