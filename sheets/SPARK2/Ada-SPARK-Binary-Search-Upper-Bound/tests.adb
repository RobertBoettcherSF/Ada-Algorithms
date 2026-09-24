with Binary_Search_Upper_Bound;
procedure Tests is
   Input : constant Binary_Search_Upper_Bound.Input_Array := [-8, -2, 0, 4, 9, 12];
begin
   pragma Assert (Binary_Search_Upper_Bound.Find (Input, -9) = 1);
   pragma Assert (Binary_Search_Upper_Bound.Find (Input, 0) = 4);
   pragma Assert (Binary_Search_Upper_Bound.Find (Input, 9) = 6);
   pragma Assert (Binary_Search_Upper_Bound.Find (Input, 12) = 7);
end Tests;
