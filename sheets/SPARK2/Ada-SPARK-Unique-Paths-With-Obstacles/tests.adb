with Unique_Paths_With_Obstacles;
procedure Tests is
   Clear : constant Unique_Paths_With_Obstacles.Grid :=
     (others => (others => False));
   Blocked : Unique_Paths_With_Obstacles.Grid := Clear;
begin
   Blocked (2, 2) := True;
   pragma Assert (Unique_Paths_With_Obstacles.Count (Clear) = 20);
   pragma Assert (Unique_Paths_With_Obstacles.Count (Blocked) = 8);
   Blocked (1, 1) := True;
   pragma Assert (Unique_Paths_With_Obstacles.Count (Blocked) = 0);
end Tests;
