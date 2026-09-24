pragma Ada_2022;

package body Sort_An_Array with SPARK_Mode => On is
   procedure Sort (Data : in out Input_Array) is
      Temp : Value;
   begin
      for I in Index loop
         for J in I + 1 .. Length loop
            if Data (J) < Data (I) then
               Temp := Data (I);
               Data (I) := Data (J);
               Data (J) := Temp;
            end if;
         end loop;
      end loop;
   end Sort;
end Sort_An_Array;
