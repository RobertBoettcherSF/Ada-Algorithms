pragma SPARK_Mode (On);

package Product_Of_Numbers_Stub is
   Capacity : constant := 5;
   subtype Number_Index is Positive range 1 .. Capacity;
   subtype Number is Natural range 0 .. 2;
   subtype Product_Value is Natural range 0 .. 32;
   type Number_Array is array (Number_Index) of Number;

   function Product (Values : Number_Array) return Product_Value
     with Global => null;
end Product_Of_Numbers_Stub;
