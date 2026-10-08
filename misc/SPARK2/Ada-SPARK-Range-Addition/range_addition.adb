pragma Ada_2022;

package body Range_Addition with SPARK_Mode => On is
   function Updated_Total
     (A : Values; Left, Right : Index; Increment : Amount) return Sum is
      Result : Sum := 0;
   begin
      for I in Left .. Right loop
         pragma Loop_Invariant
           (Result <= (Element'Last + Amount'Last) * (I - Left));
         Result := Result + A (I) + Increment;
      end loop;
      return Result;
   end Updated_Total;
end Range_Addition;
