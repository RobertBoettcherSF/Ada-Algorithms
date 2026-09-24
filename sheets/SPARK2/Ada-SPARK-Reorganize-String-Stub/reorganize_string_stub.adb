pragma Ada_2022;

package body Reorganize_String_Stub with SPARK_Mode => On is
   function Reorganize (Input : Char_Array) return Char_Array is
      Sorted : Char_Array := Input;
      Result : Char_Array := (others => ' ');
      Minimum : Index;
      Temporary : Character;
   begin
      for I in Index loop
         Minimum := I;
         for J in Index range I .. Index'Last loop
            if Sorted (J) < Sorted (Minimum) then
               Minimum := J;
            end if;
         end loop;
         Temporary := Sorted (I);
         Sorted (I) := Sorted (Minimum);
         Sorted (Minimum) := Temporary;
      end loop;
      for I in Half_Index loop
         Result (2 * I - 1) := Sorted (I);
         Result (2 * I) := Sorted (I + 4);
      end loop;
      return Result;
   end Reorganize;
end Reorganize_String_Stub;
