with Triangle_Min_Path;
procedure Tests is
   T : constant Triangle_Min_Path.Triangle :=
     ((2, 0, 0, 0), (3, 4, 0, 0), (6, 5, 7, 0), (4, 1, 8, 3));
   T2 : constant Triangle_Min_Path.Triangle :=
     ((1, 0, 0, 0), (2, 2, 0, 0), (3, 3, 3, 0), (4, 4, 4, 4));
begin
   pragma Assert (Triangle_Min_Path.Minimum (T) = 11);
   pragma Assert (Triangle_Min_Path.Minimum (T2) = 10);
end Tests;
