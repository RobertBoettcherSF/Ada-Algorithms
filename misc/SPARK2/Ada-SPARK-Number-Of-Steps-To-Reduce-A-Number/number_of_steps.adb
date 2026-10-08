pragma SPARK_Mode (On);

package body Number_Of_Steps is
   function Steps_To_Zero (Value : Number) return Step_Count is
      Current : Number := Value;
      Result  : Step_Count := 0;
   begin
      for Step in 1 .. 60 loop
         pragma Loop_Invariant (Result <= Step - 1);
         exit when Current = 0;
         if Current mod 2 = 0 then
            Current := Current / 2;
         else
            Current := Current - 1;
         end if;
         Result := Result + 1;
      end loop;
      return Result;
   end Steps_To_Zero;
end Number_Of_Steps;
