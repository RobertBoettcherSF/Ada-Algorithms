pragma Ada_2022;

package body Find_Minimum_In_Rotated_Sorted_Array_II with SPARK_Mode => On is
   function Minimum (Values : Value_Array) return Value is
      Result : Value := Values (Index'First);
   begin
      for I in Index loop
         if Values (I) < Result then
            Result := Values (I);
         end if;
      end loop;
      return Result;
   end Minimum;
end Find_Minimum_In_Rotated_Sorted_Array_II;
