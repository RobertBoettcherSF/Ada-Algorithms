pragma SPARK_Mode (On);
package body Design_Circular_Queue is
   function Empty return Queue is
   begin
      return (Values => (others => 0), Head => 1, Tail => 1, Size => 0);
   end Empty;
   function Length (Q : Queue) return Count is
   begin
      return Q.Size;
   end Length;
   procedure Enqueue (Q : in out Queue; V : Value) is
   begin
      Q.Values (Q.Tail) := V;
      case Q.Tail is
         when 1 => Q.Tail := 2;
         when 2 => Q.Tail := 3;
         when 3 => Q.Tail := 4;
         when 4 => Q.Tail := 1;
      end case;
      if Q.Size < Capacity then Q.Size := Q.Size + 1; end if;
   end Enqueue;
   procedure Dequeue (Q : in out Queue) is
   begin
      case Q.Head is
         when 1 => Q.Head := 2;
         when 2 => Q.Head := 3;
         when 3 => Q.Head := 4;
         when 4 => Q.Head := 1;
      end case;
      if Q.Size > 0 then Q.Size := Q.Size - 1; end if;
   end Dequeue;
   function Front (Q : Queue) return Value is
   begin
      return Q.Values (Q.Head);
   end Front;
end Design_Circular_Queue;
