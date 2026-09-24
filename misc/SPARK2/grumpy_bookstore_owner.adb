pragma SPARK_Mode (On);
package body Grumpy_Bookstore_Owner is
   function Max_Satisfied (Customers : Customer_Array; Grumpy : Grumpy_Array; Minutes : Minutes_Count) return Answer is
      Base : Answer := 0;
      Gain : Answer;
      Best_Gain : Answer := 0;
      Total : Answer;
   begin
      for I in Index loop
         if Grumpy (I) = 0 then
            Base := Base + Answer (Customers (I));
         end if;
      end loop;
      for Start in Index loop
         Gain := 0;
         for I in Index loop
            if I >= Start and then I - Start < Minutes then
               if Grumpy (I) = 1 then
                  Gain := Gain + Answer (Customers (I));
               end if;
            end if;
         end loop;
         if Gain > Best_Gain then Best_Gain := Gain; end if;
      end loop;
      Total := Base + Best_Gain;
      return Total;
   end Max_Satisfied;
end Grumpy_Bookstore_Owner;
