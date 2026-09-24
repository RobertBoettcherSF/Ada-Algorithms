pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with House_Robber_III_Stub; use House_Robber_III_Stub;

procedure Tests is
   Values : constant Amount_Array := (3, 2, 3, 3, 1, 2);
begin
   if Compute (Values) /= 8 then raise Program_Error; end if;
   Put_Line ("House robber III stub: PASS");
end Tests;
