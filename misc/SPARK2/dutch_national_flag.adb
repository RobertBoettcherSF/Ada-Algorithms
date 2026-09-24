pragma Ada_2022;

package body Dutch_National_Flag with SPARK_Mode => On is
   procedure Swap (Left, Right : in out Color) is
      Temporary : Color;
   begin
      Temporary := Left;
      Left := Right;
      Right := Temporary;
   end Swap;

   function Sort (Input : Color_Array) return Color_Array is
      Result : Color_Array := Input;
   begin
      for I in Index range 1 .. 4 loop
         for J in Index range I + 1 .. 5 loop
            if Result (J) < Result (I) then
               Swap (Result (I), Result (J));
            end if;
         end loop;
      end loop;
      return Result;
   end Sort;
end Dutch_National_Flag;
