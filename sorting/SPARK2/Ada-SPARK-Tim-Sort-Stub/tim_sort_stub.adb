pragma Ada_2022;

package body Tim_Sort_Stub with SPARK_Mode => On is
   function Sort (Input : Input_Array) return Input_Array is
      Work : Input_Array := Input;
      Temporary : Value;
   begin
      for I in Index loop
         for J in Index loop
            if J > I and then Work (J) < Work (I) then
               Temporary := Work (I);
               Work (I) := Work (J);
               Work (J) := Temporary;
            end if;
         end loop;
      end loop;
      return Work;
   end Sort;
end Tim_Sort_Stub;
