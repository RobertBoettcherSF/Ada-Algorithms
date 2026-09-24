pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Floyd_Warshall; use Floyd_Warshall;
procedure Tests is
   D : Distance_Matrix := (others => (others => Infinity));
begin
   for I in Node loop D (I, I) := 0; end loop;
   D (1, 2) := 3; D (2, 3) := 4; D (1, 3) := 20;
   Compute (D);
   Assert (D (1, 3) = 7);
   Put_Line ("PASS Floyd_Warshall");
end Tests;
