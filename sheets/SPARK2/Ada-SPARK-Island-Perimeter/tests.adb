with Island_Perimeter;
procedure Tests is
   Empty : constant Island_Perimeter.Grid := (others => (others => False));
   Single : Island_Perimeter.Grid := Empty;
   Block : Island_Perimeter.Grid := Empty;
begin
   Single (2, 3) := True;
   Block (2, 2) := True; Block (2, 3) := True;
   Block (3, 2) := True; Block (3, 3) := True;
   pragma Assert (Island_Perimeter.Perimeter (Empty) = 0);
   pragma Assert (Island_Perimeter.Perimeter (Single) = 4);
   pragma Assert (Island_Perimeter.Perimeter (Block) = 8);
end Tests;
