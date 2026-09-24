pragma SPARK_Mode (On);

package Design_Front_Middle_Back_Queue_Stub is
   Capacity : constant := 5;
   subtype Queue_Length is Positive range 1 .. Capacity;
   subtype Queue_Position is Positive range 1 .. Capacity;

   function Middle_Position (Length : Queue_Length) return Queue_Position
     with Global => null;
   function Length_After_Push (Length : Queue_Length) return Queue_Length
     with Global => null, Pre => Length < Capacity;
   function Length_After_Pop (Length : Queue_Length) return Natural
     with Global => null, Pre => Length > 1;
end Design_Front_Middle_Back_Queue_Stub;
