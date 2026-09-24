pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO; with Reference_Counting; use Reference_Counting;
procedure Tests is S : State;
begin
   Create (S, 1); Add_Reference (S, 1); if Reference_Count (S, 1) /= 2 then raise Program_Error; end if;
   Release (S, 1); Release (S, 1); if Reference_Count (S, 1) /= 0 then raise Program_Error; end if;
   Put_Line ("Reference counting: PASS");
end Tests;
