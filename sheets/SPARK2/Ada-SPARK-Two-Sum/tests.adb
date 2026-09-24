with Two_Sum;
procedure Tests is
   Input : constant Two_Sum.Input_Array := [3, -2, 8, 10, 4, 7];
begin
   pragma Assert (Two_Sum.Has_Pair (Input, 10));
   pragma Assert (Two_Sum.Has_Pair (Input, 5));
   pragma Assert (not Two_Sum.Has_Pair (Input, 20));
end Tests;
