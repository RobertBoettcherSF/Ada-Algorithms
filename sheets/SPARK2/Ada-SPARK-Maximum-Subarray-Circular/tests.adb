with Maximum_Subarray_Circular;
procedure Tests is
   Input : constant Maximum_Subarray_Circular.Input_Array := [5, -3, 5, -2, 4, -6, 3, 1];
begin
   pragma Assert (Maximum_Subarray_Circular.Max_Subarray (Input) = 13);
end Tests;
