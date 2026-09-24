pragma Ada_2022;
with Convex_Hull_Graham;
procedure Tests is
   use Convex_Hull_Graham;
   Points : constant Point_Array :=
     [(0, 0), (2, 0), (2, 2), (1, 1), (0, 2), (0, 0), (0, 0), (0, 0),
      (0, 0), (0, 0), (0, 0), (0, 0), (0, 0), (0, 0), (0, 0), (0, 0)];
   Hull : Point_Array;
   Count : Hull_Length;
begin
   Scan (Points, 5, Hull, Count);
   pragma Assert (Count > 0);
end Tests;
