pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions;
with Design_Circular_Queue; use Design_Circular_Queue;
with Own_Checks;
procedure Tests is
   Q : Queue := Empty;
begin
   --  Original case: 7 8 queued, front 7; dequeue, front 8.
   Enqueue (Q, 7); Enqueue (Q, 8);
   if Front (Q) /= 7 or else Length (Q) /= 2 then raise Program_Error; end if;
   Dequeue (Q);
   if Front (Q) /= 8 then raise Program_Error; end if;

   --  Hand-worked (agent A3): fill to Capacity = 4 (1 2 3 4); a fifth
   --  Enqueue is refused and changes nothing; dequeue twice (front 3),
   --  enqueue 5 and 6, which reuse the two freed ring slots: the queue is
   --  3 4 5 6 from the front. Draining it gives 3, 4, 5, 6 in that order,
   --  then Dequeue and Front on the empty queue are refused.
   declare
      F       : Queue := Empty;
      Refused : Boolean;
      Expect  : constant array (1 .. 4) of Value := [3, 4, 5, 6];
   begin
      if Length (F) /= 0 then raise Program_Error with "empty"; end if;
      Enqueue (F, 1); Enqueue (F, 2); Enqueue (F, 3); Enqueue (F, 4);
      if Length (F) /= 4 or else Element (F, 4) /= 4 then
         raise Program_Error with "full";
      end if;
      Refused := False;
      begin
         Enqueue (F, 5);
      exception
         when Ada.Assertions.Assertion_Error => Refused := True;
      end;
      if not Refused or else Length (F) /= 4 or else Front (F) /= 1 then
         raise Program_Error with "fifth enqueue";
      end if;
      Dequeue (F); Dequeue (F);
      if Front (F) /= 3 or else Length (F) /= 2 then
         raise Program_Error with "two dequeues";
      end if;
      Enqueue (F, 5); Enqueue (F, 6);
      for I in 1 .. 4 loop
         if Element (F, I) /= Expect (I) then
            raise Program_Error with "order after wrap";
         end if;
      end loop;
      for I in 1 .. 4 loop
         if Front (F) /= Expect (I) then
            raise Program_Error with "drain order";
         end if;
         Dequeue (F);
      end loop;
      Refused := False;
      begin
         Dequeue (F);
      exception
         when Ada.Assertions.Assertion_Error => Refused := True;
      end;
      if not Refused or else Length (F) /= 0 then
         raise Program_Error with "dequeue on empty";
      end if;
      Refused := False;
      declare
         Unused : Value;
      begin
         Unused := Front (F);
         Put_Line ("unexpected front" & Unused'Image);
      exception
         when Ada.Assertions.Assertion_Error => Refused := True;
      end;
      if not Refused then
         raise Program_Error with "front on empty";
      end if;
   end;

   --  Extremes of Value and a queue that turns the ring many times.
   declare
      E : Queue := Empty;
   begin
      for K in 1 .. 25 loop
         Enqueue (E, Value'First);
         Enqueue (E, Value'Last);
         if Front (E) /= Value'First then raise Program_Error with "extremes"; end if;
         Dequeue (E);
         if Front (E) /= Value'Last then raise Program_Error with "extremes"; end if;
         Dequeue (E);
         if Length (E) /= 0 then raise Program_Error with "turns"; end if;
      end loop;
   end;

   Own_Checks;
   Put_Line ("Design Circular Queue: PASS");
end Tests;
