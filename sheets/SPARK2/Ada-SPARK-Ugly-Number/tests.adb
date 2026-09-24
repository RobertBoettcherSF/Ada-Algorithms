pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Ugly_Number; use Ugly_Number;

procedure Tests is
begin
   if not Is_Ugly (6) then raise Program_Error; end if;
   if Is_Ugly (14) then raise Program_Error; end if;
   if not Is_Ugly (1) then raise Program_Error; end if;
   Put_Line ("Ugly number: PASS");
end Tests;
