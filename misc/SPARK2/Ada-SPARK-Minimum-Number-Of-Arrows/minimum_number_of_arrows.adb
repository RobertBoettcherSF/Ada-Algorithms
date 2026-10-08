pragma Ada_2022;
pragma SPARK_Mode (On);
package body Minimum_Number_Of_Arrows is
   function Arrows_Needed (Balloons : Count; Balloons_Per_Arrow : Positive_Count) return Count is
   begin
      if Balloons = 0 then return 0;
      else return (Balloons + Balloons_Per_Arrow - 1) / Balloons_Per_Arrow;
      end if;
   end Arrows_Needed;
end Minimum_Number_Of_Arrows;
