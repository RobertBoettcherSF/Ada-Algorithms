pragma Ada_2022;
pragma SPARK_Mode (On);
package body Design_Circular_Queue is
   function Empty return Queue is
   begin
      return (Values => [others => 0], Head => 1, Tail => 1, Size => 0);
   end Empty;

   procedure Enqueue (Q : in out Queue; V : Value) is
   begin
      Q.Values (Q.Tail) := V;
      Q.Tail := Slot (Q.Tail, 1);
      Q.Size := Q.Size + 1;
   end Enqueue;

   procedure Dequeue (Q : in out Queue) is
   begin
      Q.Head := Slot (Q.Head, 1);
      Q.Size := Q.Size - 1;
   end Dequeue;

   function Front (Q : Queue) return Value is
   begin
      return Q.Values (Q.Head);
   end Front;
end Design_Circular_Queue;
