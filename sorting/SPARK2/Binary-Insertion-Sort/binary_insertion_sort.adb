pragma Ada_2022;

package body Binary_Insertion_Sort with SPARK_Mode => On is
   function Sort (Input : Input_Array) return Sort_Result is
      Work : Input_Array := Input;
      Temporary : Value;
      Probes : Natural := 0;
   begin
      -- A fixed number of bounded compare-exchange passes keeps this
      -- reference implementation small and completely analyzable.
      for Pass in Index loop
         for I in Index loop
            if I < Index'Last then
               Probes := Probes + 1;
               if Work (I) > Work (I + 1) then
                  Temporary := Work (I);
                  Work (I) := Work (I + 1);
                  Work (I + 1) := Temporary;
               end if;
            end if;
         end loop;
      end loop;
      return (Sorted => Work, Probes => Probes);
   end Sort;
end Binary_Insertion_Sort;
