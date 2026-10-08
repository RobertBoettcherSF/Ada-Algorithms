pragma Ada_2022;

package body Sort_Characters_By_Frequency with SPARK_Mode => On is
   function Frequency (Input : Char_Array; Candidate : Character) return Integer is
      Count : Integer := 0;
   begin
      for I in Index loop
         if Input (I) = Candidate then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Frequency;

   function Sort_By_Frequency (Input : Char_Array) return Char_Array is
      Work : Char_Array := Input;
      Temporary : Character;
   begin
      for I in Index loop
         for J in Index loop
            if J > I
              and then Frequency (Work, Work (J)) > Frequency (Work, Work (I))
            then
               Temporary := Work (I);
               Work (I) := Work (J);
               Work (J) := Temporary;
            end if;
         end loop;
      end loop;
      return Work;
   end Sort_By_Frequency;
end Sort_Characters_By_Frequency;
