with Remove_Duplicates_Sorted;
procedure Tests is
   use type Remove_Duplicates_Sorted.Result_Array;
   Input : constant Remove_Duplicates_Sorted.Input_Array := [1, 1, 2, 4, 4];
   Expected : constant Remove_Duplicates_Sorted.Result_Array := [1, 2, 4, -11, -11];
begin
   pragma Assert (Remove_Duplicates_Sorted.Remove_Duplicates (Input) = Expected);
end Tests;
