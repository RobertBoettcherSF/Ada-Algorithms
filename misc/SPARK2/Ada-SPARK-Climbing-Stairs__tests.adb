with Climbing_Stairs;
procedure Tests is
begin
   pragma Assert (Climbing_Stairs.Count (0) = 1);
   pragma Assert (Climbing_Stairs.Count (2) = 2);
   pragma Assert (Climbing_Stairs.Count (5) = 8);
   pragma Assert (Climbing_Stairs.Count (10) = 89);
end Tests;
