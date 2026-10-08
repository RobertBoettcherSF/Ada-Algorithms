pragma SPARK_Mode (On);

package body Sort_Colors is
   procedure Sort (Data : in out Colors; Length : Length_Type) is
      Temp : Color;
   begin
      for I in Index loop
         exit when I >= Length;
         for J in Index loop
            exit when J >= Length;
            if J < Index'Last and then Data (J) > Data (J + 1) then
               Temp := Data (J);
               Data (J) := Data (J + 1);
               Data (J + 1) := Temp;
            end if;
         end loop;
      end loop;
   end Sort;
end Sort_Colors;
