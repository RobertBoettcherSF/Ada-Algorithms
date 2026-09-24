with Ada.Assertions; use Ada.Assertions;
with Sum_Powers_Three; use Sum_Powers_Three;

procedure Tests is
begin
   Assert (Is_Sum_Of_Powers_Of_Three (0));
   Assert (Is_Sum_Of_Powers_Of_Three (4));
   Assert (Is_Sum_Of_Powers_Of_Three (12));
   Assert (not Is_Sum_Of_Powers_Of_Three (2));
   Assert (not Is_Sum_Of_Powers_Of_Three (5));
end Tests;
