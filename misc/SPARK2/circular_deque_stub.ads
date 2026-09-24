pragma SPARK_Mode (On);

package Circular_Deque_Stub is
   Capacity : constant := 4;
   subtype Count is Natural range 0 .. Capacity;
   subtype Value is Integer range -100 .. 100;

   type Deque is record
      Size : Count := 0;
      V1, V2, V3, V4 : Value := 0;
   end record;

   function Empty return Deque;
   function Push_Front (D : Deque; V : Value) return Deque;
   function Push_Back (D : Deque; V : Value) return Deque;
   function Pop_Front (D : Deque) return Deque;
   function Pop_Back (D : Deque) return Deque;
   function Front (D : Deque) return Value;
   function Back (D : Deque) return Value;
end Circular_Deque_Stub;
