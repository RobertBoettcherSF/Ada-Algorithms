pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO; with Clock_Page_Replacement; use Clock_Page_Replacement;
procedure Tests is S : State;
begin
   Access_Page (S, 1); Access_Page (S, 2); Access_Page (S, 3); Access_Page (S, 4); Access_Page (S, 1);
   if Fault_Count (S) /= 4 then raise Program_Error; end if;
   Access_Page (S, 5); if Fault_Count (S) /= 5 then raise Program_Error; end if;
   --  V&V sweep, agent A3: 101 different pages are 101 faults; the count
   --  must not stop at 100.
   declare
      Many : State;
   begin
      for P in Clock_Page_Replacement.Page loop
         Access_Page (Many, P);
      end loop;
      if Fault_Count (Many) /= 101 then
         raise Program_Error with "101 faults counted as" & Fault_Count (Many)'Image;
      end if;
   end;
   Put_Line ("Clock: PASS");
end Tests;
