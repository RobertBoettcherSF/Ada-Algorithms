pragma Ada_2022;
package body Number_Of_Provinces with SPARK_Mode => On is
   function Count_Provinces (Connections : Connection_Matrix) return Province_Count is
      Count : Province_Count := 0;
   begin
      for C in City loop
         if Connections (C, C) and then Count < Province_Count'Last then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Provinces;
end Number_Of_Provinces;
