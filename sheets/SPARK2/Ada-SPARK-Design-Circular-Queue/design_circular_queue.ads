pragma SPARK_Mode (On);
package Design_Circular_Queue is
   Capacity : constant := 4;
   subtype Value is Integer range -100 .. 100;
   subtype Count is Natural range 0 .. Capacity;
   type Queue is private;
   function Empty return Queue with Global => null;
   function Length (Q : Queue) return Count with Global => null;
   procedure Enqueue (Q : in out Queue; V : Value) with Global => null,
     Pre => Length (Q) < Capacity;
   procedure Dequeue (Q : in out Queue) with Global => null,
     Pre => Length (Q) > 0;
   function Front (Q : Queue) return Value with Global => null,
     Pre => Length (Q) > 0;
private
   subtype Index is Positive range 1 .. Capacity;
   type Value_Array is array (Index) of Value;
   type Queue is record
      Values : Value_Array := (others => 0);
      Head : Index := 1;
      Tail : Index := 1;
      Size : Count := 0;
   end record;
end Design_Circular_Queue;
