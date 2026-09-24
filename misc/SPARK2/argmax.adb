pragma SPARK_Mode (On);

package body Argmax is
   function Find (Values : Element_Array) return Index is
      Best : Index := Index'First;
   begin
      for I in Index loop
         if Values (I) > Values (Best) then
            Best := I;
         end if;
      end loop;
      return Best;
   end Find;
end Argmax;
