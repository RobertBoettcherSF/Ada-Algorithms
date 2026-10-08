pragma SPARK_Mode (On);

package body Reduce_Array_Size_To_The_Half is
   function Groups_To_Remove
     (Length, Largest_Group : Array_Length) return Group_Count is
   begin
      if Length = 0 then
         return 0;
      elsif Largest_Group * 2 >= Length then
         return 1;
      else
         return 2;
      end if;
   end Groups_To_Remove;
end Reduce_Array_Size_To_The_Half;
