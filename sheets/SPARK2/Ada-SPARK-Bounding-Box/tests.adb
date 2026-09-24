pragma Ada_2022;
with Bounding_Box;
procedure Tests is
   Points : constant Bounding_Box.Point_Array :=
     [(0, 5), (3, -2), (-4, 1), (2, 7), (0, 0), (0, 0), (0, 0), (0, 0), (0, 0), (0, 0), (0, 0), (0, 0), (0, 0), (0, 0), (0, 0), (0, 0)] ;
   Result : constant Bounding_Box.Box := Bounding_Box.Enclose (Points, 4);
begin
   pragma Assert (Result.Min_X = -4 and Result.Min_Y = -2);
   pragma Assert (Result.Max_X = 3 and Result.Max_Y = 7);
end Tests;
