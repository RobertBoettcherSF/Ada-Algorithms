with Missing_Number;
procedure Tests is
   Missing_Three : constant Missing_Number.Input_Array := [0, 1, 2, 4, 5];
   Missing_Zero : constant Missing_Number.Input_Array := [1, 2, 3, 4, 5];
begin
   pragma Assert (Missing_Number.Find (Missing_Three) = 3);
   pragma Assert (Missing_Number.Find (Missing_Zero) = 0);
end Tests;
