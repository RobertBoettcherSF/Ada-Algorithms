pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Prims_Algorithm; use Prims_Algorithm;
procedure Tests is
   G : Weight_Matrix := (others => (others => Infinity));
   P : Parent_Array;
begin
   G (1, 1) := 0; G (2, 2) := 0; G (3, 3) := 0;
   G (1, 2) := 1; G (2, 1) := 1; G (2, 3) := 2; G (3, 2) := 2;
   Compute (G, P);
   Assert (P (2) = 1 and then P (3) = 2);
   Put_Line ("PASS Prims_Algorithm");
end Tests;
