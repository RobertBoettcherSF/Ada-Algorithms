pragma SPARK_Mode (On);
package Design_Circular_Deque is
   Capacity : constant := 4;
   subtype Value is Integer range -100 .. 100;
   subtype Count is Natural range 0 .. Capacity;
   type Deque is private;
   function Empty return Deque with Global => null;
   function Length (D : Deque) return Count with Global => null;
   procedure Push_Front (D : in out Deque; V : Value) with Global => null,
     Pre => Length (D) < Capacity;
   procedure Push_Back (D : in out Deque; V : Value) with Global => null,
     Pre => Length (D) < Capacity;
   procedure Pop_Front (D : in out Deque) with Global => null,
     Pre => Length (D) > 0;
   function Front (D : Deque) return Value with Global => null,
     Pre => Length (D) > 0;
private
   subtype Index is Positive range 1 .. Capacity;
   type Value_Array is array (Index) of Value;
   type Deque is record
      Values : Value_Array := (others => 0);
      Size : Count := 0;
   end record;
end Design_Circular_Deque;
