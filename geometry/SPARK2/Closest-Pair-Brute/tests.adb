pragma Ada_2022;
with Closest_Pair_Brute;
procedure Tests is
   Points : constant Closest_Pair_Brute.Point_Array :=
     [(0, 0), (5, 5), (2, 1), (-8, 3), (9, 9), (0, 0), (0, 0), (0, 0),
      (0, 0), (0, 0), (0, 0), (0, 0), (0, 0), (0, 0), (0, 0), (0, 0)];
begin
   pragma Assert (Closest_Pair_Brute.Distance_Squared (Points (1), Points (3)) = 5);
   pragma Assert (Closest_Pair_Brute.Find (Points, 4) = 5);
end Tests;
