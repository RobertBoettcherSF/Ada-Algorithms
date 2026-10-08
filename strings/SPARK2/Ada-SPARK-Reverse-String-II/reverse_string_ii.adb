pragma SPARK_Mode (On);

package body Reverse_String_II is
   procedure Reverse_First (Data : in out Items; Length : Length_Type) is
      Temp : Character;
   begin
      for I in Index loop
         exit when I > Length;
         for J in Index loop
            exit when J > Length;
            if I + J = Length + 1 and then I < J then
               Temp := Data (I);
               Data (I) := Data (J);
               Data (J) := Temp;
            end if;
         end loop;
      end loop;
   end Reverse_First;
end Reverse_String_II;
