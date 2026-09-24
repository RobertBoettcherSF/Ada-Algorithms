pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO; with Bakery; use Bakery;
procedure Tests is S : State;
begin
   Take_Number (S, 1); Take_Number (S, 2);
   if not Can_Enter (S, 1) then raise Program_Error; end if;
   if Can_Enter (S, 2) then raise Program_Error; end if;
   Leave (S, 1); if not Can_Enter (S, 2) then raise Program_Error; end if;
   Put_Line ("Bakery: PASS");
end Tests;
