pragma Ada_2022;

package body Find_Median_From_Data_Stream with SPARK_Mode => On is
   function Median (Input : Input_Array; Count : Count_Index) return Value is
      Work : Input_Array := Input;
      Temporary : Value;
   begin
      for I in Index loop
         for J in Index loop
            if I <= Count and then J <= Count and then J > I
              and then Work (J) < Work (I)
            then
               Temporary := Work (I);
               Work (I) := Work (J);
               Work (J) := Temporary;
            end if;
         end loop;
      end loop;
      if Count mod 2 = 1 then
         return Work ((Count + 1) / 2);
      else
         return (Work (Count / 2) + Work (Count / 2 + 1)) / 2;
      end if;
   end Median;
end Find_Median_From_Data_Stream;
