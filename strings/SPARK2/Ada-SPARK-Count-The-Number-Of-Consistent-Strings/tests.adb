with Count_The_Number_Of_Consistent_Strings;
procedure Tests is
   Input : constant Count_The_Number_Of_Consistent_Strings.Input_Array := [1, 4, 2, 7];
begin
   pragma Assert (Count_The_Number_Of_Consistent_Strings.Count_Consistent (Input, 4) = 3);
end Tests;
