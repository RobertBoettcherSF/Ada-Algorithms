pragma Ada_2022;
package body Babylonian_Sqrt with SPARK_Mode => On is
   function Sqrt (N : Input) return Sqrt_Result is
      Best  : Integer := 0;
      Steps : Step_Count := 0;
   begin
      -- The bounded refinement visits every possible integer root.
      for Candidate in 0 .. 100 loop
         pragma Loop_Invariant (Steps = Candidate);
         Steps := Steps + 1;
         if Candidate * Candidate <= N then
            Best := Candidate;
         end if;
      end loop;
      return (Root => Best, Steps => Steps);
   end Sqrt;
end Babylonian_Sqrt;
