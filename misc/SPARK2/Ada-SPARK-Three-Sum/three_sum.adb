pragma SPARK_Mode (On);

package body Three_Sum is
   function Has_Triple_Sum (Data : Values; Length : Length_Type; Goal : Target)
     return Boolean is
   begin
      for I in Index loop
         exit when I > Length;
         for J in Index loop
            exit when J > Length;
            for K in Index loop
               exit when K > Length;
               if Data (I) + Data (J) + Data (K) = Goal then
                  return True;
               end if;
            end loop;
         end loop;
      end loop;
      return False;
   end Has_Triple_Sum;
end Three_Sum;
