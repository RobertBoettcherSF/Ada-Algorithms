pragma SPARK_Mode (On);

package Design_Circular_Queue_Stub is
   Capacity : constant := 5;
   subtype Count is Natural range 0 .. Capacity;
   subtype Position is Positive range 1 .. Capacity;

   function Enqueued_Length (Current : Count) return Count
     with Global => null, Pre => Current < Capacity;
   function Dequeued_Length (Current : Count) return Count
     with Global => null, Pre => Current > 0;
   function Next_Position (Current : Position) return Position
     with Global => null;
end Design_Circular_Queue_Stub;
