with Two_Pointers_Sum;
procedure Tests is
   Input : constant Two_Pointers_Sum.Input_Array := [1, 3, 5, 7, 9];
begin
   pragma Assert (Two_Pointers_Sum.Has_Pair (Input, 12));
   pragma Assert (not Two_Pointers_Sum.Has_Pair (Input, 20));
end Tests;
