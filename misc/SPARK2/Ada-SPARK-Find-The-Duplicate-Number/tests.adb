with Find_The_Duplicate_Number;
procedure Tests is
   Input : constant Find_The_Duplicate_Number.Input_Array := [1, 3, 4, 2, 2, 5, 6, 7];
begin
   pragma Assert (Find_The_Duplicate_Number.Duplicate (Input) = 2);
end Tests;
