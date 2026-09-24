pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Happy_Number; use Happy_Number;

procedure Tests is
begin
   if not Is_Happy (19) then raise Program_Error; end if;
   if Is_Happy (2) then raise Program_Error; end if;
   if not Is_Happy (1) then raise Program_Error; end if;
   Put_Line ("Happy number: PASS");
end Tests;
