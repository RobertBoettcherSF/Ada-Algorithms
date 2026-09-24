with Maximal_Square;
procedure Tests is
   use Maximal_Square;
begin
   pragma Assert (Largest_Side (((1, 1, 1, 1), (1, 1, 1, 1), (1, 1, 1, 1), (1, 1, 1, 1))) = 4);
   pragma Assert (Largest_Side (((1, 1, 0, 0), (1, 1, 1, 0), (0, 1, 1, 0), (0, 0, 0, 0))) = 2);
   pragma Assert (Largest_Side (((0, 0, 0, 0), (0, 0, 0, 0), (0, 0, 0, 0), (0, 0, 0, 0))) = 0);
end Tests;
