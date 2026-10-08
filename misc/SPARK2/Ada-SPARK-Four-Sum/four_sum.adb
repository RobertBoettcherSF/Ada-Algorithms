pragma SPARK_Mode (On);

package body Four_Sum is
   function Has_Four_Sum (Data : Values; Length : Length_Type; Goal : Target)
     return Boolean is
   begin
      for I in Index loop
         exit when I > Length;
         for J in Index loop
            exit when J > Length;
            for K in Index loop
               exit when K > Length;
               for M in Index loop
                  exit when M > Length;
                  if Data (I) + Data (J) + Data (K) + Data (M) = Goal then
                     return True;
                  end if;
               end loop;
            end loop;
         end loop;
      end loop;
      return False;
   end Has_Four_Sum;
end Four_Sum;
