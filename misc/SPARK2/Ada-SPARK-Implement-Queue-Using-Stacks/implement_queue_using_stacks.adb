pragma Ada_2022;
package body Implement_Queue_Using_Stacks with SPARK_Mode => On is
   function Empty return Queue is
   begin return (Data => [others => 0], Head => 1, Tail => 1, Count => 0); end Empty;
   procedure Enqueue (Q : in out Queue; V : Value) is
   begin
      Q.Data (Q.Tail) := V;
      if Q.Tail = Capacity then Q.Tail := 1; else Q.Tail := Q.Tail + 1; end if;
      Q.Count := Q.Count + 1;
   end Enqueue;
   procedure Dequeue (Q : in out Queue; V : out Value) is
   begin
      V := Q.Data (Q.Head);
      if Q.Head = Capacity then Q.Head := 1; else Q.Head := Q.Head + 1; end if;
      Q.Count := Q.Count - 1;
   end Dequeue;
   function Size (Q : Queue) return Natural is (Q.Count);
end Implement_Queue_Using_Stacks;
