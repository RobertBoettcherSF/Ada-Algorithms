with Last_Stone_Weight_II;
procedure Tests is
   use Last_Stone_Weight_II;
begin
   pragma Assert (Min_Remaining_Weight ((2, 7, 4, 1, 8, 1)) = 1);
   pragma Assert (Min_Remaining_Weight ((10, 9, 8, 7, 6, 5)) = 1);
   pragma Assert (Min_Remaining_Weight ((0, 0, 0, 0, 0, 0)) = 0);
end Tests;
