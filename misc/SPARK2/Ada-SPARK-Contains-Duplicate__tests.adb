with Contains_Duplicate;
procedure Tests is
   With_Duplicate : constant Contains_Duplicate.Input_Array := [1, 4, 7, 4, 9, 2];
   Without_Duplicate : constant Contains_Duplicate.Input_Array := [1, 4, 7, 8, 9, 2];
begin
   pragma Assert (Contains_Duplicate.Has_Duplicate (With_Duplicate));
   pragma Assert (not Contains_Duplicate.Has_Duplicate (Without_Duplicate));
end Tests;
