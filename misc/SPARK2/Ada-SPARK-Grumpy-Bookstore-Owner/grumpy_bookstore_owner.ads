pragma SPARK_Mode (On);
package Grumpy_Bookstore_Owner is
   Element_Count : constant := 8;
   subtype Index is Positive range 1 .. Element_Count;
   subtype Customers_Count is Natural range 0 .. 32;
   type Customer_Array is array (Index) of Customers_Count;
   subtype Bit is Integer range 0 .. 1;
   type Grumpy_Array is array (Index) of Bit;
   subtype Minutes_Count is Positive range 1 .. Element_Count;
   type Answer is mod 257;
   function Max_Satisfied (Customers : Customer_Array; Grumpy : Grumpy_Array; Minutes : Minutes_Count) return Answer;
end Grumpy_Bookstore_Owner;
