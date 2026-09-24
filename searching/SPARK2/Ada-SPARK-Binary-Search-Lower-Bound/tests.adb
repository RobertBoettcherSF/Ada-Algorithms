with Binary_Search_Lower_Bound;
procedure Tests is
   Input : constant Binary_Search_Lower_Bound.Input_Array := [-8, -2, 0, 4, 9, 12];
begin
   pragma Assert (Binary_Search_Lower_Bound.Find (Input, -9) = 1);
   pragma Assert (Binary_Search_Lower_Bound.Find (Input, 0) = 3);
   pragma Assert (Binary_Search_Lower_Bound.Find (Input, 10) = 6);
   pragma Assert (Binary_Search_Lower_Bound.Find (Input, 20) = 7);
end Tests;
