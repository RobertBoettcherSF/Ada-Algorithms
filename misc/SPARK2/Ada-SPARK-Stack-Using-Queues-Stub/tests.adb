pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Stack_Using_Queues_Stub; use Stack_Using_Queues_Stub;

procedure Tests is
   S : Stack := Empty;
begin
   S := Push (S, 1); S := Push (S, 2); S := Push (S, 3);
   if Top (S) /= 3 then raise Program_Error; end if;
   S := Pop (S);
   if Top (S) /= 2 then raise Program_Error; end if;
   Put_Line ("Stack using queues stub: PASS");
end Tests;
