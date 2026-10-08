pragma SPARK_Mode (On);

package body Sqrtx is
   function Integer_Square_Root (Value : Input) return Root is
      Result : Root := 0;
   begin
      for Candidate in reverse Root loop
         if Candidate * Candidate <= Value then
            Result := Candidate;
            exit;
         end if;
      end loop;
      return Result;
   end Integer_Square_Root;
end Sqrtx;
