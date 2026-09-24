pragma Ada_2022;

package body Median_Of_Two_Sorted_Arrays_Lite with SPARK_Mode => On is
   function Median (Left : Input_Array; Right : Input_Array) return Value is
      Work : array (Combined_Index) of Value :=
        [Left (1), Left (2), Left (3), Left (4),
         Right (1), Right (2), Right (3), Right (4)];
      Min_Pos : Combined_Index;
      Temp : Value;
   begin
      for I in Combined_Index loop
         Min_Pos := I;
         for J in Combined_Index range I .. Combined_Index'Last loop
            if Work (J) < Work (Min_Pos) then
               Min_Pos := J;
            end if;
         end loop;
         Temp := Work (I);
         Work (I) := Work (Min_Pos);
         Work (Min_Pos) := Temp;
      end loop;
      return (Work (4) + Work (5)) / 2;
   end Median;
end Median_Of_Two_Sorted_Arrays_Lite;
