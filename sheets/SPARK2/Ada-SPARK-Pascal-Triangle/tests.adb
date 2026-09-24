pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Pascal_Triangle; use Pascal_Triangle;

procedure Tests is
begin
   if Row_Total (0) /= 1 or else Row_Total (5) /= 32 then
      raise Program_Error;
   end if;
   Put_Line ("Pascal Triangle: PASS");
end Tests;
