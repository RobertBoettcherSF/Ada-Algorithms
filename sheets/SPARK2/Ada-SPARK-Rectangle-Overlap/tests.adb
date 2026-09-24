with Rectangle_Overlap; use Rectangle_Overlap;
procedure Tests with SPARK_Mode => Off is
   A : constant Rectangle := (Left => 0, Bottom => 0, Right => 4, Top => 4);
   B : constant Rectangle := (Left => 2, Bottom => 1, Right => 6, Top => 3);
   C : constant Rectangle := (Left => 4, Bottom => 0, Right => 8, Top => 4);
begin
   pragma Assert (Has_Overlap (A, B));
   pragma Assert (not Has_Overlap (A, C));
end Tests;
