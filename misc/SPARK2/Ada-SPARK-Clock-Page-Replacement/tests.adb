pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO; with Clock_Page_Replacement; use Clock_Page_Replacement;
procedure Tests is S : State;
begin
   Access_Page (S, 1); Access_Page (S, 2); Access_Page (S, 3); Access_Page (S, 4); Access_Page (S, 1);
   if Fault_Count (S) /= 4 then raise Program_Error; end if;
   Access_Page (S, 5); if Fault_Count (S) /= 5 then raise Program_Error; end if;
   Put_Line ("Clock: PASS");
end Tests;
