pragma SPARK_Mode (On);

package body Trapping_Rain_Water_II_Lite is
   function Trapped (Data : Heights; Length : Length_Type) return Natural is
      Total : Natural := 0;
      Left_Max : Height;
      Right_Max : Height;
      Level : Height;
   begin
      for I in Index loop
         pragma Loop_Invariant (Total <= 1_000 * (I - 1));
         exit when I > Length;
         Left_Max := Data (I);
         for J in Index loop
            exit when J >= I;
            if Data (J) > Left_Max then
               Left_Max := Data (J);
            end if;
         end loop;
         Right_Max := Data (I);
         for J in Index loop
            exit when J > Length;
            if J > I and then Data (J) > Right_Max then
               Right_Max := Data (J);
            end if;
         end loop;
         if Left_Max < Right_Max then
            Level := Left_Max;
         else
            Level := Right_Max;
         end if;
         if Level > Data (I) then
            Total := Total + Level - Data (I);
         end if;
      end loop;
      return Total;
   end Trapped;
end Trapping_Rain_Water_II_Lite;
