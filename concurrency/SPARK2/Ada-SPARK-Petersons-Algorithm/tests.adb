pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO; with Peterson; use Peterson;
procedure Tests is S : State;
begin
   Request_Entry (S, First); if not Can_Enter (S, First) then raise Program_Error; end if;
   Request_Entry (S, Second); if Can_Enter (S, First) and Can_Enter (S, Second) then raise Program_Error; end if;
   Leave (S, First); if not Can_Enter (S, Second) then raise Program_Error; end if;
   Put_Line ("Peterson: PASS");
end Tests;
