pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Argmax; use Argmax;

procedure Tests is
   Values : constant Element_Array := (-4, 7, 3, 12, 1);
begin
   if Find (Values) /= 4 then raise Program_Error; end if;
   Put_Line ("Argmax: PASS");
end Tests;
