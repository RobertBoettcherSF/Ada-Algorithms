with Ada.Text_IO; use Ada.Text_IO;
with Design_Circular_Queue; use Design_Circular_Queue;
procedure Tests is
   Q : Queue := Empty;
begin
   Enqueue (Q, 7); Enqueue (Q, 8);
   if Front (Q) /= 7 or else Length (Q) /= 2 then raise Program_Error; end if;
   Dequeue (Q);
   if Front (Q) /= 8 then raise Program_Error; end if;
   Put_Line ("Design Circular Queue: PASS");
end Tests;
