with Intersection_Of_Two_Arrays_II;
procedure Tests is
   Left  : constant Intersection_Of_Two_Arrays_II.Input_Array := [1, 2, 2, 3];
   Right : constant Intersection_Of_Two_Arrays_II.Input_Array := [4, 2, 5, 6];
   Other : constant Intersection_Of_Two_Arrays_II.Input_Array := [4, 5, 6, 7];
begin
   pragma Assert (Intersection_Of_Two_Arrays_II.Has_Common (Left, Right));
   pragma Assert (not Intersection_Of_Two_Arrays_II.Has_Common (Left, Other));
end Tests;
