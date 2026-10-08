pragma SPARK_Mode (On);

package Ordered_Stream_Stub is
   Stream_Size : constant := 4;
   subtype Stream_Index is Positive range 1 .. Stream_Size;
   subtype Used_Count is Natural range 0 .. Stream_Size;
   subtype Item_Id is Positive range 1 .. Stream_Size;
   type Item_Array is array (Stream_Index) of Item_Id;

   function Prefix_Count
     (Items : Item_Array; Used : Used_Count) return Natural;
end Ordered_Stream_Stub;
