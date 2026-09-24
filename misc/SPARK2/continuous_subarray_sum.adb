pragma Ada_2022;

package body Continuous_Subarray_Sum with SPARK_Mode => On is
   function Total (A : Values) return Sum is
      Result : Sum := 0;
   begin
      for I in Index loop
         pragma Loop_Invariant
           (Result <= Element'Last * (I - Index'First));
         Result := Result + A (I);
      end loop;
      return Result;
   end Total;
end Continuous_Subarray_Sum;
