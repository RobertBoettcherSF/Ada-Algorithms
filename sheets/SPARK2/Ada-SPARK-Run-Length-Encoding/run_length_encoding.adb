pragma Ada_2022;
package body Run_Length_Encoding with SPARK_Mode => On is
   function Number_Of_Runs (Input : Char_Array) return Run_Count is
      Count : Run_Count := 1;
   begin
      for I in Input'First + 1 .. Input'Last loop
         if Input (I) /= Input (I - 1) and then Count < Run_Count'Last then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Number_Of_Runs;
end Run_Length_Encoding;
