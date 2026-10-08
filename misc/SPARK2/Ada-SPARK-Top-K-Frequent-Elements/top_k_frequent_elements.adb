pragma Ada_2022;

package body Top_K_Frequent_Elements with SPARK_Mode => On is
   function Frequency (Input : Input_Array; Candidate : Value) return Integer is
      Count : Integer := 0;
   begin
      for I in Index loop
         if Input (I) = Candidate then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Frequency;

   function Kth_Most_Frequent (Input : Input_Array; K : K_Index) return Value is
      Work : Input_Array := Input;
      Temporary : Value;
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
      return Work (K);
   end Kth_Most_Frequent;
end Top_K_Frequent_Elements;
