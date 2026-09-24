pragma SPARK_Mode (On);

package body Ordered_Stream_Stub is
   function Prefix_Count
     (Items : Item_Array; Used : Used_Count) return Natural is
      Count : Natural range 0 .. Stream_Size := 0;
   begin
      for I in Stream_Index loop
         if I <= Used and then Count = I - 1 and then Items (I) = I then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Prefix_Count;
end Ordered_Stream_Stub;
