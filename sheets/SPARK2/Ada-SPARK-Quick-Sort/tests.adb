pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Quick_Sort; use Quick_Sort;
procedure Tests is
   Input : constant Input_Array := (1 => 23, 2 => 4, 3 => 17, 4 => 9,
                                    5 => 1, 6 => 31, 7 => 12, 8 => 6);
   Result : constant Input_Array := Sort (Input);
begin
   for I in Index loop
      if I < Index'Last then
         Assert (Result (I) <= Result (I + 1));
      end if;
   end loop;
   Put_Line ("PASS Quick_Sort");
end Tests;
