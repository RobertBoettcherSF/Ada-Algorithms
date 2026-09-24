with Merge_Sorted_Arrays;
procedure Tests is
   use type Merge_Sorted_Arrays.Output_Array;
   Left : constant Merge_Sorted_Arrays.Input_Array := [1, 4, 9];
   Right : constant Merge_Sorted_Arrays.Input_Array := [2, 3, 8];
   Expected : constant Merge_Sorted_Arrays.Output_Array := [1, 2, 3, 4, 8, 9];
begin
   pragma Assert (Merge_Sorted_Arrays.Merge (Left, Right) = Expected);
end Tests;
