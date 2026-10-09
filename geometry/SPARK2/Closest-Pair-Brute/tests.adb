pragma Ada_2022;
with Ada.Text_IO;
with Closest_Pair_Brute; use Closest_Pair_Brute;
with Own_Checks;
procedure Tests is
   Points : constant Closest_Pair_Brute.Point_Array :=
     [(0, 0), (5, 5), (2, 1), (-8, 3), (9, 9), (0, 0), (0, 0), (0, 0),
      (0, 0), (0, 0), (0, 0), (0, 0), (0, 0), (0, 0), (0, 0), (0, 0)];
   Far : Point_Array := [others => (0, 0)];
begin
   pragma Assert (Closest_Pair_Brute.Distance_Squared (Points (1), Points (3)) = 5);
   pragma Assert (Closest_Pair_Brute.Find (Points, 4) = 5);

   --  Hand-worked (V&V sweep, agent A3).
   --  One point: no pair, Long_Long_Integer'Last.
   pragma Assert (Find (Points, 1) = Long_Long_Integer'Last);
   --  (3, 0) and (5, 0) are 2 apart: 4 (a sum instead of a difference
   --  would give 64).
   pragma Assert (Distance_Squared ((3, 0), (5, 0)) = 4);
   pragma Assert (Distance_Squared ((0, -7), (0, -4)) = 9);
   --  Opposite corners: 2000 ** 2 + 2000 ** 2.
   Far (1) := (-1000, -1000);
   Far (2) := (1000, 1000);
   pragma Assert (Find (Far, 2) = 8_000_000);
   --  The closest pair uses the last point: (100, 100), (-100, 50),
   --  (300, -20), (101, 99) -> (100, 100)-(101, 99) = 2.
   Far (1) := (100, 100);
   Far (2) := (-100, 50);
   Far (3) := (300, -20);
   Far (4) := (101, 99);
   pragma Assert (Find (Far, 4) = 2);
   pragma Assert (Find (Far, 3) = 200 ** 2 + 50 ** 2);
   --  Repeated points are 0 apart.
   pragma Assert (Find (Points, 7) = 0);

   Own_Checks;
   Ada.Text_IO.Put_Line ("closest pair brute: PASS");
end Tests;
