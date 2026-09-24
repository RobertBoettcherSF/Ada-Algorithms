pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Tim_Sort_Stub; use Tim_Sort_Stub;
procedure Tests is
   Input : constant Input_Array := (1 => 4, 2 => 1, 3 => 7, 4 => 3,
                                    5 => 2, 6 => 8, 7 => 5, 8 => 6);
   Result : constant Input_Array := Sort (Input);
begin
   Assert (Result (1) = 1);
   Assert (Result (8) = 8);
   for I in Index range 1 .. Index'Last - 1 loop
      Assert (Result (I) <= Result (I + 1));
   end loop;
   Put_Line ("PASS Tim_Sort_Stub");
end Tests;
