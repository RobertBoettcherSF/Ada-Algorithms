pragma SPARK_Mode (On);

package Queue_Using_Stacks is
   Capacity : constant := 4;
   subtype Count is Natural range 0 .. Capacity;
   subtype Value is Integer range -100 .. 100;

   type Queue is record
      Size : Count := 0;
      V1, V2, V3, V4 : Value := 0;
   end record;

   function Empty return Queue;
   function Enqueue (Q : Queue; V : Value) return Queue
     with Pre => Q.Size < Capacity;
   function Dequeue (Q : Queue) return Queue
     with Pre => Q.Size > 0;
   function Front (Q : Queue) return Value
     with Pre => Q.Size > 0;
end Queue_Using_Stacks;
