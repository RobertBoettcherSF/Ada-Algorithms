pragma Ada_2022;
package body Run_Length_Encoding with SPARK_Mode => On is
   function Number_Of_Runs (Input : Char_Array) return Run_Count is
      Count : Run_Count;
   begin
      if Input'Length = 0 then
         return 0;
      end if;
      Count := 1;
      --  Compare each cell with its successor. Input'Last - 1 never
      --  overflows, unlike Input'First + 1 when Input'First = Positive'Last.
      for I in Input'First .. Input'Last - 1 loop
         if Input (I + 1) /= Input (I) then
            Count := Count + 1;
         end if;
         pragma Loop_Invariant (Count in 1 .. I - Input'First + 2);
      end loop;
      return Count;
   end Number_Of_Runs;
end Run_Length_Encoding;
