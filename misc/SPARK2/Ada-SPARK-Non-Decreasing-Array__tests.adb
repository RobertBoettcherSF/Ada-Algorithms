pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Non_Decreasing_Array; use Non_Decreasing_Array;
procedure Tests is
begin
   pragma Assert (Can_Be_Non_Decreasing (1, 2, 3));
   pragma Assert (Can_Be_Non_Decreasing (3, 1, 2));
   pragma Assert (not Can_Be_Non_Decreasing (3, 2, 1));
   Put_Line ("PASS Ada-SPARK-Non-Decreasing-Array");
end Tests;
