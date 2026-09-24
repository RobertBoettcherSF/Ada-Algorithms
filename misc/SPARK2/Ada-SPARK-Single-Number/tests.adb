with Single_Number;
procedure Tests is
   Input : constant Single_Number.Input_Array := [4, 1, 2, 1, 2];
   Negative : constant Single_Number.Input_Array := [-7, 3, -7, 3, 9];
begin
   pragma Assert (Single_Number.Find (Input) = 4);
   pragma Assert (Single_Number.Find (Negative) = 9);
end Tests;
