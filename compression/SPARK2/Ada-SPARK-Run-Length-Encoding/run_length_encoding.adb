pragma Ada_2022;
package body Run_Length_Encoding with SPARK_Mode => On is
   function Number_Of_Runs (Input : Char_Array) return Run_Count is
      Count : Run_Count;
   begin
      if Input'Length = 0 then
         return 0;
      end if;
      Count := 1;
      for I in Input'First + 1 .. Input'Last loop
         if Input (I) /= Input (I - 1) then
            Count := Count + 1;
         end if;
         pragma Loop_Invariant (Count in 1 .. I - Input'First + 1);
      end loop;
      return Count;
   end Number_Of_Runs;
end Run_Length_Encoding;
