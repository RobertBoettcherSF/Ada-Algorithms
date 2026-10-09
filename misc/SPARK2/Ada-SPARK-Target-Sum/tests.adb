pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Target_Sum; use Target_Sum;
with Own_Checks;
procedure Tests is
   A : constant Values := [1, 1, 1, 1];
   --  Hand-worked (agent A3): four 4s reach +16 and -16 one way each (all
   --  plus, all minus), the edges of Target; 0 has C (4, 2) = 6 ways.
   Fours : constant Values := [4, 4, 4, 4];
   --  1, 2, 3 (N = 3): +1+2-3 = 0 and -1-2+3 = 0, so 2 ways to reach 0;
   --  6 only as +1+2+3.
   Small : constant Values := [1, 2, 3, 4];
begin
   Assert (Ways_To_Target (A, 4, 2) = 4);
   Assert (Ways_To_Target (A, 4, 0) = 6);
   Assert (Ways_To_Target (A, 0, 0) = 1);
   Assert (Ways_To_Target (Fours, 4, 16) = 1);
   Assert (Ways_To_Target (Fours, 4, -16) = 1);
   Assert (Ways_To_Target (Fours, 4, 0) = 6);
   Assert (Ways_To_Target (Small, 3, 0) = 2);
   Assert (Ways_To_Target (Small, 3, 6) = 1);
   Assert (Ways_To_Target (Small, 3, 5) = 0);
   Own_Checks;
end Tests;
