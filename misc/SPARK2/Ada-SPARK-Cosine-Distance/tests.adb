with Ada.Text_IO;
with Cosine_Distance; use Cosine_Distance;
with Own_Checks;
procedure Tests is
   A : constant Vector := [1, 2, 3];
   B : constant Vector := [1, 2, 3];
   C : constant Vector := [3, 2, 1];
   Empty : constant Vector := [0, 0, 0];
begin
   pragma Assert (Distance (A, A) = 0);
   pragma Assert (Distance (A, B) = 0);
   pragma Assert (Distance (A, C) = 490);
   pragma Assert (Distance (Empty, Empty) = 0);
   --  Hand-worked (V&V sweep, agent A3; tests/SOURCES.txt).
   pragma Assert (Distance ([1, 0, 0], [0, 1, 0]) = 1000);
   pragma Assert (Distance ([3, 0, 0], [0, 0, 2]) = 1000);
   pragma Assert (Distance ([1, 1, 0], [1, 0, 0]) = 500);
   pragma Assert (Distance ([1, 0, 0], [1, 1, 0]) = 500);
   pragma Assert (Distance ([1, 1, 1], [1, 0, 0]) = 667);
   pragma Assert (Distance ([1, 1, 1], [1, 1, 0]) = 334);
   pragma Assert (Distance ([1, 1, 0], [3, 3, 0]) = 0);
   pragma Assert (Distance ([3, 3, 3], [1, 1, 1]) = 0);
   pragma Assert (Distance ([3, 3, 3], [3, 3, 2]) = 31);
   pragma Assert (Distance ([1, 2, 0], [2, 1, 0]) = 360);
   pragma Assert (Distance ([0, 0, 0], [1, 2, 3]) = 0);
   pragma Assert (Distance ([1, 2, 3], [0, 0, 0]) = 0);
   Own_Checks;
   Ada.Text_IO.Put_Line ("PASS Cosine_Distance");
end Tests;
