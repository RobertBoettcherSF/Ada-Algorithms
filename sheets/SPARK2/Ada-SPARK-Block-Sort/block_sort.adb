pragma Ada_2022;

package body Block_Sort with SPARK_Mode => On is
   function Sort (Input : Input_Array) return Input_Array is
      Work : Input_Array := Input;
      Temporary : Value;
   begin
      -- A fixed number of bounded compare-exchange passes keeps this
      -- reference implementation small and completely analyzable.
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
end Block_Sort;
