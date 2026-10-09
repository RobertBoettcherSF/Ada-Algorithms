--  Pre rejection: misc/SPARK2/Ada-SPARK-Stack-Bounded (Push, Pop, Top).
--  Stack of depth uniform 0 .. Capacity (that many Pushes after Initialize).
with Pre_Rng; use Pre_Rng;
with Stack_Bounded; use Stack_Bounded;
procedure Pr_Stack is
   R_Push, R_Pop : Natural := 0;
   function Pre_Push (S : Stack) return Boolean is (Depth (S) < Capacity);
   function Pre_Pop (S : Stack) return Boolean is (Depth (S) > 0);
begin
   for K in 1 .. Sample loop
      declare
         S : Stack;
         D : constant Natural := Draw (0, Capacity);
      begin
         Initialize (S);
         for I in 1 .. D loop Push (S, Draw (-100, 100)); end loop;
         if not Pre_Push (S) then R_Push := R_Push + 1; end if;
         if not Pre_Pop (S) then R_Pop := R_Pop + 1; end if;
      end;
   end loop;
   Report ("misc/SPARK2/Ada-SPARK-Stack-Bounded", "Push", "depth uniform 0..Capacity", R_Push);
   Report ("misc/SPARK2/Ada-SPARK-Stack-Bounded", "Pop / Top", "depth uniform 0..Capacity", R_Pop);
end Pr_Stack;
