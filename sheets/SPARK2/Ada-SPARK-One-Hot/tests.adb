pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with One_Hot; use One_Hot;

procedure Tests is
   Result : constant Vector := Encode (3);
begin
   if Result /= (False, False, True, False) then raise Program_Error; end if;
   Put_Line ("One_Hot: PASS");
end Tests;
