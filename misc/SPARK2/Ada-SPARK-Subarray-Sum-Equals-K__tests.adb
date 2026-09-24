with Subarray_Sum_Equals_K;
procedure Tests is
   Input : constant Subarray_Sum_Equals_K.Input_Array := [1, 2, 3, -2, 2, 1];
begin
   pragma Assert (Subarray_Sum_Equals_K.Count (Input, 3) = 5);
   pragma Assert (Subarray_Sum_Equals_K.Count (Input, 30) = 0);
end Tests;
