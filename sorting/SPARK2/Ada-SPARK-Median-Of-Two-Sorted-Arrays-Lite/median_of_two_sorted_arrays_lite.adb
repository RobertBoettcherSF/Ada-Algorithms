pragma Ada_2022;

package body Median_Of_Two_Sorted_Arrays_Lite with SPARK_Mode => On is
   function Median (Left : Input_Array; Right : Input_Array) return Median_Result is
      Work : array (Combined_Index) of Value :=
        [for I in Combined_Index => (if I <= Length then Left (I) else Right (I - Length))];
      Min_Pos : Combined_Index;
      Temp : Value;
      Probes : Natural := 0;
   begin
      for I in Combined_Index loop
         Min_Pos := I;
         for J in Combined_Index range I .. Combined_Index'Last loop
            if J > I then
               Probes := Probes + 1;
            end if;
            if Work (J) < Work (Min_Pos) then
               Min_Pos := J;
            end if;
         end loop;
         Temp := Work (I);
         Work (I) := Work (Min_Pos);
         Work (Min_Pos) := Temp;
      end loop;
      return (Median => (Work (Length) + Work (Length + 1)) / 2, Probes => Probes);
   end Median;
end Median_Of_Two_Sorted_Arrays_Lite;
