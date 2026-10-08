pragma Ada_2022;

package body Bitonic_Sort with SPARK_Mode => On is
   function Sort (Input : Input_Array) return Input_Array is
      Work : Input_Array := Input;
      Temporary : Value;
   begin
      -- A fixed, bounded compare-exchange network keeps this reference
      -- implementation small and fully analyzable at proof level 2.
      for Pass in Index loop
         for I in Index loop
            if I < Index'Last and then Work (I) > Work (I + 1) then
               Temporary := Work (I);
               Work (I) := Work (I + 1);
               Work (I + 1) := Temporary;
            end if;
         end loop;
      end loop;
      return Work;
   end Sort;
end Bitonic_Sort;
