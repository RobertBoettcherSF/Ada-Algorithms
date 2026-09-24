with How_Many_Numbers_Are_Smaller;
procedure Tests is
   Input : constant How_Many_Numbers_Are_Smaller.Input_Array := [8, 1, 5, 3, 9];
begin
   pragma Assert (How_Many_Numbers_Are_Smaller.Count_Smaller (Input, 6) = 3);
end Tests;
