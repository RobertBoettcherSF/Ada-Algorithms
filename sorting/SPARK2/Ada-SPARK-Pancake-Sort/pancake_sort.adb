pragma Ada_2022;

package body Pancake_Sort with SPARK_Mode => On is
   function Sort (Input : Input_Array) return Input_Array is
      Work : Input_Array := Input;
      Temporary : Value;
   begin
      --  The bounded core uses compare-and-swap passes, the same small
      --  in-place discipline as a pancake-sort exercise.
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
end Pancake_Sort;
