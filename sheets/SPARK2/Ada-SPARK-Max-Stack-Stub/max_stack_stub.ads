pragma SPARK_Mode (On);

package Max_Stack_Stub is
   Capacity : constant := 4;
   subtype Count is Natural range 0 .. Capacity;
   subtype Value is Integer range -100 .. 100;

   type Stack is record
      Size : Count := 0;
      V1, V2, V3, V4 : Value := 0;
   end record;

   function Empty return Stack;
   function Push (S : Stack; V : Value) return Stack;
   function Pop (S : Stack) return Stack;
   function Top_Value (S : Stack) return Value;
   function Max_Value (S : Stack) return Value;
end Max_Stack_Stub;
