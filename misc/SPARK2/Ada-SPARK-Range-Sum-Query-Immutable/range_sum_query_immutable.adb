pragma Ada_2022;

package body Range_Sum_Query_Immutable with SPARK_Mode => On is
   function Query (A : Values; Left, Right : Index) return Sum is
      Result : Sum := 0;
   begin
      for I in Left .. Right loop
         pragma Loop_Invariant (Result <= Element'Last * (I - Left));
         Result := Result + A (I);
      end loop;
      return Result;
   end Query;
end Range_Sum_Query_Immutable;
