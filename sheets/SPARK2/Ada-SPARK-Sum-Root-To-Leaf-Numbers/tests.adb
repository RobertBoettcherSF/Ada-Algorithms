pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Sum_Root_To_Leaf_Numbers; use Sum_Root_To_Leaf_Numbers;
procedure Tests is
   Input : constant Tree := (1 => 1, 2 => 2, 3 => 3, 4 => 4, 5 => 5,
                             6 => 6, 7 => 7, 8 => 8, 9 => 9, 10 => 0,
                             11 => 1, 12 => 2, 13 => 3, 14 => 4, 15 => 5);
begin
   Assert (Sum_Root_To_Leaf (Input) = 1_248 + 1_249 + 1_250 + 1_251
           + 1_362 + 1_363 + 1_374 + 1_375);
   Put_Line ("PASS Sum_Root_To_Leaf_Numbers");
end Tests;
