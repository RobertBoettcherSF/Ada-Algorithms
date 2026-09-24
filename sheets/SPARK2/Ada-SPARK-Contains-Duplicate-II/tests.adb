with Contains_Duplicate_II;
procedure Tests is
   Near : constant Contains_Duplicate_II.Input_Array := [1, 4, 7, 4, 9, 2, 8, 6];
   Far : constant Contains_Duplicate_II.Input_Array := [1, 4, 7, 8, 9, 2, 1, 6];
begin
   pragma Assert (Contains_Duplicate_II.Has_Nearby_Duplicate (Near));
   pragma Assert (not Contains_Duplicate_II.Has_Nearby_Duplicate (Far));
end Tests;
