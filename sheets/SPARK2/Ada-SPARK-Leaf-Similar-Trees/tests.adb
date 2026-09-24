pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Leaf_Similar_Trees; use Leaf_Similar_Trees;
procedure Tests is
   Left : constant Tree := (1 => 1, 2 => 2, 3 => 3, 8 => 5, 9 => 6, others => 0);
   Same : constant Tree := (1 => 9, 2 => 8, 3 => 7, 8 => 5, 9 => 6, others => 0);
   Different : constant Tree := (1 => 9, 2 => 8, 3 => 7, 8 => 5, 9 => 7, others => 0);
begin
   Assert (Leaf_Similar (Left, Same));
   Assert (not Leaf_Similar (Left, Different));
   Put_Line ("PASS Leaf_Similar_Trees");
end Tests;
