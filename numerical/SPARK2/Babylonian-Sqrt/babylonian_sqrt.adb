pragma Ada_2022;
package body Babylonian_Sqrt with SPARK_Mode => On is
   function Sqrt (N : Input) return Integer is
      Best : Integer := 0;
   begin
      -- The bounded refinement visits every possible integer root.
      for Candidate in 0 .. 100 loop
         if Candidate * Candidate <= N then
            Best := Candidate;
         end if;
      end loop;
      return Best;
   end Sqrt;
end Babylonian_Sqrt;
