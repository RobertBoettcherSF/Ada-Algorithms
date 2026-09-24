pragma SPARK_Mode (On);

package body Maximum_Performance_Of_A_Team_Lite is
   function Best_Single_Performance
     (Speeds : Speed_Array; Efficiencies : Efficiency_Array) return Natural
   is
      Best : Natural := 0;
   begin
      for I in Speeds'Range loop
         if Speeds (I) * Efficiencies (I) > Best then
            Best := Speeds (I) * Efficiencies (I);
         end if;
      end loop;
      return Best;
   end Best_Single_Performance;
end Maximum_Performance_Of_A_Team_Lite;
