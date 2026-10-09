pragma SPARK_Mode (On);

package body Sqrtx is
   function Integer_Square_Root (Value : Input) return Root_Result is
      Result : Root := 0;
      Probes : Probe_Count := 0;
   begin
      for Candidate in reverse Root loop
         pragma Loop_Invariant (Probes = Root'Last - Candidate);
         Probes := Probes + 1;
         if Candidate * Candidate <= Value then
            Result := Candidate;
            exit;
         end if;
      end loop;
      return (Value => Result, Probes => Probes);
   end Integer_Square_Root;
end Sqrtx;
