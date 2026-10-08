pragma Ada_2022;

package body Count_Smaller_After_Self with SPARK_Mode => On is
   function Count (Input : Input_Array) return Count_Array is
      Result : Count_Array;
      Smaller : Count_Range;
   begin
      for I in Index loop
         Smaller := 0;
         for J in I + 1 .. Length loop
            pragma Loop_Invariant (Smaller <= J - I);
            if Input (J) < Input (I) then
               Smaller := Smaller + 1;
            end if;
         end loop;
         Result (I) := Smaller;
      end loop;
      return Result;
   end Count;
end Count_Smaller_After_Self;
