pragma Ada_2022;

package body Sort_Characters_By_Frequency with SPARK_Mode => On is
   --  selection sort of the characters by Rank (computed against the original Input)
   function Sort_By_Frequency (Input : Char_Array) return Char_Array is
      Work : Char_Array := Input;
      Best : Index;
      Temporary : Character;
   begin
      for I in Index loop
         Best := I;
         for J in I + 1 .. Index'Last loop
            if Rank (Input, Work (J)) < Rank (Input, Work (Best)) then
               Best := J;
            end if;
            pragma Loop_Invariant (Best in I .. J);
            pragma Loop_Invariant (for all K in I .. J => Rank (Input, Work (Best)) <= Rank (Input, Work (K)));
         end loop;
         Temporary := Work (I);
         Work (I) := Work (Best);
         Work (Best) := Temporary;
         pragma Loop_Invariant (for all K in 1 .. I - 1 => Rank (Input, Work (K)) <= Rank (Input, Work (K + 1)));
         pragma Loop_Invariant (for all K in 1 .. I =>
                                  (for all L in I + 1 .. Index'Last => Rank (Input, Work (K)) <= Rank (Input, Work (L))));
      end loop;
      return Work;
   end Sort_By_Frequency;
end Sort_Characters_By_Frequency;
