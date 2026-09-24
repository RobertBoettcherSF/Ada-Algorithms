pragma Ada_2022;

package body Merge_K_Sorted_Lists_Stub with SPARK_Mode => On is
   function Merge_K (Input : Input_Array) return Input_Array is
      Result : Input_Array := Input;
      Minimum : Index;
      Temporary : Value;
   begin
      for I in Index loop
         Minimum := I;
         for J in Index range I .. Index'Last loop
            if Result (J) < Result (Minimum) then
               Minimum := J;
            end if;
         end loop;
         Temporary := Result (I);
         Result (I) := Result (Minimum);
         Result (Minimum) := Temporary;
      end loop;
      return Result;
   end Merge_K;
end Merge_K_Sorted_Lists_Stub;
