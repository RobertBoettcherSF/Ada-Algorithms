with Domino_And_Tromino_Tiling_Lite;
procedure Tests is
begin
   pragma Assert (Domino_And_Tromino_Tiling_Lite.Number_Of_Tilings (0) = 1);
   pragma Assert (Domino_And_Tromino_Tiling_Lite.Number_Of_Tilings (4) = 11);
   pragma Assert (Domino_And_Tromino_Tiling_Lite.Number_Of_Tilings (16) = 144_467);
end Tests;
