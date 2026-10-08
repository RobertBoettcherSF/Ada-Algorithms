pragma Ada_2022;
with Point_In_Polygon;
with Own_Checks;
procedure Tests is
   use Point_In_Polygon;
   Square : constant Polygon := [(0, 0), (10, 0), (10, 10), (0, 10)];
begin
   pragma Assert (Contains (Square, 4, (5, 5)));
   pragma Assert (not Contains (Square, 4, (15, 5)));
   Own_Checks;
end Tests;
