pragma SPARK_Mode (On);
package body Maximum_Points_You_Can_Obtain_From_Cards is
   function Max_Points (Cards : Card_Array; K : Take_Count) return Answer is
      Total : Answer;
      Best : Answer := 0;
      Take_Right : Take_Count;
   begin
      for Take_Left in Take_Count loop
         if Take_Left <= K then
            Take_Right := K - Take_Left;
            if Take_Right <= Element_Count - Take_Left then
               Total := 0;
               for I in Index loop
                  if I <= Take_Left then
                     Total := Total + Answer (Cards (I));
                  elsif I > Element_Count - Take_Right then
                     Total := Total + Answer (Cards (I));
                  end if;
               end loop;
               if Total > Best then Best := Total; end if;
            end if;
         end if;
      end loop;
      return Best;
   end Max_Points;
end Maximum_Points_You_Can_Obtain_From_Cards;
