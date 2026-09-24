pragma SPARK_Mode (On);

package body Two_Sum_II_Input_Array_Is_Sorted is
   function Has_Pair (Data : Values; Length : Length_Type; Goal : Target)
     return Boolean is
   begin
      for I in Index loop
         exit when I > Length;
         for J in Index loop
            exit when J > Length;
            if I < J and then Data (I) + Data (J) = Goal then
               return True;
            end if;
         end loop;
      end loop;
      return False;
   end Has_Pair;
end Two_Sum_II_Input_Array_Is_Sorted;
