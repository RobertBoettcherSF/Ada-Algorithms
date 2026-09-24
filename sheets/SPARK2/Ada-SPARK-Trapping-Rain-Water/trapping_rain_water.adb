pragma SPARK_Mode (On);

package body Trapping_Rain_Water is
   function Trapped (Data : Heights; Length : Length_Type) return Water is
      Total : Water := 0;
      Left_Max : Height;
      Right_Max : Height;
      Limit : Height;
   begin
      for I in Index loop
         pragma Loop_Invariant (Total <= 1_000 * (I - 1));
         exit when I > Length;
         Left_Max := 0;
         Right_Max := 0;
         for J in Index loop
            exit when J > Length;
            if J <= I and then Data (J) > Left_Max then
               Left_Max := Data (J);
            end if;
            if J >= I and then Data (J) > Right_Max then
               Right_Max := Data (J);
            end if;
         end loop;
         if Left_Max < Right_Max then
            Limit := Left_Max;
         else
            Limit := Right_Max;
         end if;
         if Data (I) < Limit then
            Total := Total + Limit - Data (I);
         end if;
      end loop;
      return Total;
   end Trapped;
end Trapping_Rain_Water;
