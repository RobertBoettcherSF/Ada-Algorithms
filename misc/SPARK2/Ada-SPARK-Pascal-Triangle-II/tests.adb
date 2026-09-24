pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Pascal_Triangle_II; use Pascal_Triangle_II;

procedure Tests is
begin
   if Get (0, 0) /= 1 or else Get (4, 2) /= 6 or else Get (4, 5) /= 0 then
      raise Program_Error;
   end if;
   Put_Line ("Pascal Triangle II: PASS");
end Tests;
