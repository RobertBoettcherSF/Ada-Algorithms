with Ada.Assertions; use Ada.Assertions;
with Asteroid_Collision; use Asteroid_Collision;
procedure Tests is
begin
   Assert (Resolve_Pair (5, -3) = 5);
   Assert (Resolve_Pair (5, -5) = 0);
   Assert (Resolve_Pair (3, -7) = -7);
   Assert (Resolve_Pair (-2, 4) = 4);
end Tests;
