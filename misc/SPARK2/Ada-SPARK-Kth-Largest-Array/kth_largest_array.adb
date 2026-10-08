pragma Ada_2022;

package body Kth_Largest_Array with SPARK_Mode => On is
   function Kth_Largest (Input : Input_Array; K : K_Range) return Value is
      Work : Input_Array := Input; Temp : Value;
   begin
      for I in Index loop
         for J in I + 1 .. Length loop
            if Work (J) > Work (I) then Temp := Work (I); Work (I) := Work (J); Work (J) := Temp; end if;
         end loop;
      end loop;
      return Work (K);
   end Kth_Largest;
end Kth_Largest_Array;
