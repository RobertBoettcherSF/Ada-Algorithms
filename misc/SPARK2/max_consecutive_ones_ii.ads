pragma SPARK_Mode (On);
package Max_Consecutive_Ones_II is
   Element_Count : constant := 8;
   subtype Index is Positive range 1 .. Element_Count;
   subtype Bit is Integer range 0 .. 1;
   type Bit_Array is array (Index) of Bit;
   subtype Count is Natural range 0 .. Element_Count;
   function Find (Bits : Bit_Array) return Count;
end Max_Consecutive_Ones_II;
