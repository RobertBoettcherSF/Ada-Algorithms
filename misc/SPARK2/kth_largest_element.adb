pragma Ada_2022;

package body Kth_Largest_Element with SPARK_Mode => On is
   function Kth_Largest (Input : Input_Array; K : K_Index) return Value is
      Work : Input_Array := Input;
      Temporary : Value;
   begin
      for I in Index loop
         for J in Index loop
            if J > I and then Work (J) > Work (I) then
               Temporary := Work (I);
               Work (I) := Work (J);
               Work (J) := Temporary;
            end if;
         end loop;
      end loop;
      return Work (K);
   end Kth_Largest;
end Kth_Largest_Element;
