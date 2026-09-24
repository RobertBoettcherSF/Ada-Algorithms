with Perfect_Squares;
procedure Tests is
begin
   pragma Assert (Perfect_Squares.Minimum (0) = 0);
   pragma Assert (Perfect_Squares.Minimum (7) = 4);
   pragma Assert (Perfect_Squares.Minimum (12) = 3);
   pragma Assert (Perfect_Squares.Minimum (16) = 1);
end Tests;
