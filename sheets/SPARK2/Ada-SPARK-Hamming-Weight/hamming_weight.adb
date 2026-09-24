pragma SPARK_Mode (On);

package body Hamming_Weight is
   function Weight (Value : Input) return Count is
      Work : Input := Value;
      Result : Count := 0;
   begin
      for Bit in 1 .. 32 loop
         pragma Loop_Invariant (Result <= Bit - 1);
         if Work mod 2 = 1 then
            Result := Result + 1;
         end if;
         Work := Work / 2;
      end loop;
      return Result;
   end Weight;
end Hamming_Weight;
