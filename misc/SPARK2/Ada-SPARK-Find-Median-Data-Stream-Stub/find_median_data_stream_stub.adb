pragma Ada_2022;

package body Find_Median_Data_Stream_Stub with SPARK_Mode => On is
   function Median (Input : Input_Array; Count : Count_Index) return Value is
      Work : Input_Array := (others => 0);
      Minimum : Index;
      Temporary : Value;
   begin
      for I in Index range 1 .. Count loop
         Work (I) := Input (I);
      end loop;
      for I in Index range 1 .. Count loop
         Minimum := I;
         for J in Index range I .. Count loop
            if Work (J) < Work (Minimum) then
               Minimum := J;
            end if;
         end loop;
         Temporary := Work (I);
         Work (I) := Work (Minimum);
         Work (Minimum) := Temporary;
      end loop;
      if Count mod 2 = 1 then
         return Work ((Count + 1) / 2);
      else
         return (Work (Count / 2) + Work (Count / 2 + 1)) / 2;
      end if;
   end Median;
end Find_Median_Data_Stream_Stub;
