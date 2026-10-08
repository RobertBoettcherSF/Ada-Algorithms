pragma Ada_2022;

package body Find_The_Smallest_Divisor with SPARK_Mode => On is
   function Smallest_Divisor
     (Values : Value_Array; Limit : Threshold) return Divisor is
   begin
      for Candidate in Divisor loop
         declare
            Total : Integer := 0;
         begin
            for I in Index loop
               Total := Total +
                 (Integer (Values (I)) + Integer (Candidate) - 1) /
                 Integer (Candidate);
            end loop;
            if Total <= Integer (Limit) then
               return Candidate;
            end if;
         end;
      end loop;
      return Divisor'Last;
   end Smallest_Divisor;
end Find_The_Smallest_Divisor;
