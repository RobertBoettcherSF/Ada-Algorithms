pragma SPARK_Mode (On);

package body Kth_Largest_Element_In_A_Stream is
   function Kth_Largest (Stream : Stream_Array; K : K_Range) return Value is
      Work : Stream_Array := Stream;
   begin
      for I in 1 .. Stream_Length - 1 loop
         for J in I + 1 .. Stream_Length loop
            if Work (J) > Work (I) then
               declare
                  Temp : constant Value := Work (I);
               begin
                  Work (I) := Work (J);
                  Work (J) := Temp;
               end;
            end if;
         end loop;
      end loop;
      return Work (K);
   end Kth_Largest;
end Kth_Largest_Element_In_A_Stream;
