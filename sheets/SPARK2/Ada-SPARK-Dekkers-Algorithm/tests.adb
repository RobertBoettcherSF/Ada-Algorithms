pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO; with Dekker; use Dekker;
procedure Tests is S : State;
begin
   Request (S, First); Request (S, Second);
   if Can_Enter (S, First) = Can_Enter (S, Second) then Back_Off (S, Second); end if;
   if not Can_Enter (S, First) then raise Program_Error; end if;
   Leave (S, First); if not Can_Enter (S, Second) then raise Program_Error; end if;
   Put_Line ("Dekker: PASS");
end Tests;
