pragma Ada_2022;
package body Degree_Of_An_Array with SPARK_Mode => On is
   function Degree (A : Int_Array) return Count is
      Best : Count := 0;
      Occurrences : Count;
   begin
      for I in Index loop
         Occurrences := 0;
         for J in Index loop
            if A (J) = A (I) and then Occurrences < Length then
               Occurrences := Occurrences + 1;
            end if;
         end loop;
         if Occurrences > Best then
            Best := Occurrences;
         end if;
      end loop;
      return Best;
   end Degree;
end Degree_Of_An_Array;
