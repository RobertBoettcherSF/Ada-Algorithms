pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with The_Skyline_Problem_Lite; use The_Skyline_Problem_Lite;

procedure Tests is
   Buildings : constant Building_Array := (3, 8, 5, 2, 8, 1, 4, 6);
   Flat      : constant Building_Array := (0, 0, 0, 0, 0, 0, 0, 0);
begin
   if Skyline_Height (Buildings) /= 8 then raise Program_Error; end if;
   if Skyline_Height (Flat) /= 0 then raise Program_Error; end if;
   Put_Line ("Skyline lite: PASS");
end Tests;
