pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Median_Of_Three; use Median_Of_Three;

procedure Tests is
begin
   if Median (9, 2, 5) /= 5 then raise Program_Error; end if;
   if Median (-4, -8, -6) /= -6 then raise Program_Error; end if;
   Put_Line ("Median_Of_Three: PASS");
end Tests;
