pragma SPARK_Mode (On);

package Delete_And_Earn_Stub is
   Value_Count : constant := 6;
   subtype Index is Positive range 1 .. Value_Count;
   subtype Value is Integer range 1 .. 10;
   subtype Result is Integer range 0 .. 600;
   type Value_Array is array (Index) of Value;

   function Compute (Values : Value_Array) return Result;
end Delete_And_Earn_Stub;
