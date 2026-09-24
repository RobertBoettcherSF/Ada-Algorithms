with Minimum_Path_Sum;
procedure Tests is
   G : constant Minimum_Path_Sum.Grid :=
     ((1, 3, 1, 2), (1, 5, 1, 3), (4, 2, 1, 7), (3, 1, 2, 1));
   Flat : constant Minimum_Path_Sum.Grid := (others => (others => 2));
begin
   pragma Assert (Minimum_Path_Sum.Minimum (G) = 10);
   pragma Assert (Minimum_Path_Sum.Minimum (Flat) = 14);
end Tests;
