pragma SPARK_Mode (On);

package body Design_Circular_Queue_Stub is
   function Enqueued_Length (Current : Count) return Count is
   begin
      return Current + 1;
   end Enqueued_Length;

   function Dequeued_Length (Current : Count) return Count is
   begin
      return Current - 1;
   end Dequeued_Length;

   function Next_Position (Current : Position) return Position is
   begin
      if Current = Position'Last then
         return Position'First;
      else
         return Current + 1;
      end if;
   end Next_Position;
end Design_Circular_Queue_Stub;
