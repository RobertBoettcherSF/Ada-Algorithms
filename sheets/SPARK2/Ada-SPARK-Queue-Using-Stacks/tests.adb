pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Queue_Using_Stacks; use Queue_Using_Stacks;

procedure Tests is
   Q : Queue := Empty;
begin
   Q := Enqueue (Q, 10); Q := Enqueue (Q, 20); Q := Enqueue (Q, 30);
   if Front (Q) /= 10 then raise Program_Error; end if;
   Q := Dequeue (Q);
   if Front (Q) /= 20 then raise Program_Error; end if;
   Put_Line ("Queue using stacks: PASS");
end Tests;
