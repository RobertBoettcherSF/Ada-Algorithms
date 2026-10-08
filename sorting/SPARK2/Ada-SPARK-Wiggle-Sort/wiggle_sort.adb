pragma Ada_2022;

package body Wiggle_Sort with SPARK_Mode => On is
   function Wiggle (Input : Input_Array) return Input_Array is
      Work : Input_Array := Input;
      Temporary : Value;
   begin
      for I in Index loop
         if I < Index'Last then
            if I mod 2 = 1 and then Work (I) > Work (I + 1) then
               Temporary := Work (I);
               Work (I) := Work (I + 1);
               Work (I + 1) := Temporary;
            elsif I mod 2 = 0 and then Work (I) < Work (I + 1) then
               Temporary := Work (I);
               Work (I) := Work (I + 1);
               Work (I + 1) := Temporary;
            end if;
         end if;
      end loop;
      return Work;
   end Wiggle;
end Wiggle_Sort;
