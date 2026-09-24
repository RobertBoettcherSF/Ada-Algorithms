with Dutch_National_Flag;
procedure Tests is
   use type Dutch_National_Flag.Color_Array;
   Input : constant Dutch_National_Flag.Color_Array := [2, 0, 2, 1, 0];
   Expected : constant Dutch_National_Flag.Color_Array := [0, 0, 1, 2, 2];
begin
   pragma Assert (Dutch_National_Flag.Sort (Input) = Expected);
end Tests;
