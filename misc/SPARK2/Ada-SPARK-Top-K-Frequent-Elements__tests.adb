pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Top_K_Frequent_Elements; use Top_K_Frequent_Elements;
procedure Tests is
   Input : constant Input_Array := (1 => 1, 2 => 2, 3 => 2, 4 => 3,
                                    5 => 3, 6 => 3, 7 => 3, 8 => 1);
begin
   Assert (Kth_Most_Frequent (Input, 1) = 3);
   Assert (Kth_Most_Frequent (Input, 2) = 3);
   Put_Line ("PASS Top_K_Frequent_Elements");
end Tests;
