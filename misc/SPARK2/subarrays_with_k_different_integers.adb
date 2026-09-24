pragma SPARK_Mode (On);
package body Subarrays_With_K_Different_Integers is
   type Seen_Array is array (Value) of Boolean;
   function Count (Values : Element_Array; K : Different_Count) return Answer is
      Total : Answer := 0;
      Distinct : Different_Count;
      Seen : Seen_Array;
   begin
      for Start in Index loop
         Seen := (others => False);
         Distinct := 0;
         for Finish in Index loop
            if Finish >= Start then
               if not Seen (Values (Finish)) then
                  Seen (Values (Finish)) := True;
                  if Distinct < Different_Count'Last then
                     Distinct := Distinct + 1;
                  end if;
               end if;
               if Distinct = K and then Total < Answer'Last then
                  Total := Total + 1;
               end if;
            end if;
         end loop;
      end loop;
      return Total;
   end Count;
end Subarrays_With_K_Different_Integers;
