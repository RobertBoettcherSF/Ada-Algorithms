pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Super_Ugly_Number; use Super_Ugly_Number;

procedure Tests is
begin
   if Super_Ugly (1) /= 1 then raise Program_Error; end if;
   if Super_Ugly (5) /= 5 then raise Program_Error; end if;
   if Super_Ugly (8) /= 9 then raise Program_Error; end if;
   Put_Line ("Super ugly number: PASS");
end Tests;
