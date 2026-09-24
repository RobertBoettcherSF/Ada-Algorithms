pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Pancake_Sort; use Pancake_Sort;
procedure Tests is
   Input : constant Input_Array := (1 => 4, 2 => 1, 3 => 7, 4 => 3,
                                    5 => 2, 6 => 8, 7 => 5, 8 => 6);
   Result : constant Input_Array := Sort (Input);
begin
   for I in Index range 1 .. Index'Last - 1 loop
      Assert (Result (I) <= Result (I + 1));
   end loop;
   Put_Line ("PASS Pancake_Sort");
end Tests;
