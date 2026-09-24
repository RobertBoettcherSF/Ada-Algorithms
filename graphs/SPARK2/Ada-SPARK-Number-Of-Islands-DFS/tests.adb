with Number_Of_Islands_DFS;
procedure Tests is
   Empty : constant Number_Of_Islands_DFS.Grid := (others => (others => False));
   G : Number_Of_Islands_DFS.Grid := Empty;
   Two : Number_Of_Islands_DFS.Grid := Empty;
begin
   G (1, 1) := True; G (1, 2) := True; G (2, 1) := True;
   Two (1, 1) := True; Two (4, 4) := True;
   pragma Assert (Number_Of_Islands_DFS.Count (Empty) = 0);
   pragma Assert (Number_Of_Islands_DFS.Count (G) = 1);
   pragma Assert (Number_Of_Islands_DFS.Count (Two) = 2);
end Tests;
