pragma Ada_2022;

package body Find_The_Smallest_Divisor with SPARK_Mode => On is
   function Smallest_Divisor
     (Values : Value_Array; Limit : Threshold) return Divisor is
   begin
      for Candidate in Divisor'First .. Divisor'Last - 1 loop
         pragma Loop_Invariant
           (Candidate = 1 or else Quotient_Sum (Values, Candidate - 1) > Limit);
         declare
            Total : Natural := 0;
         begin
            for I in Index loop
               pragma Loop_Invariant
                 (Total = (if I > 1 then Quotient (Values (1), Candidate) else 0)
                          + (if I > 2 then Quotient (Values (2), Candidate) else 0)
                          + (if I > 3 then Quotient (Values (3), Candidate) else 0)
                          + (if I > 4 then Quotient (Values (4), Candidate) else 0)
                          + (if I > 5 then Quotient (Values (5), Candidate) else 0)
                          + (if I > 6 then Quotient (Values (6), Candidate) else 0)
                          + (if I > 7 then Quotient (Values (7), Candidate) else 0));
               Total := Total + Quotient (Values (I), Candidate);
            end loop;
            pragma Assert (Total = Quotient_Sum (Values, Candidate));
            if Total <= Integer (Limit) then
               return Candidate;
            end if;
            pragma Assert (Quotient_Sum (Values, Candidate) > Limit);
         end;
      end loop;
      --  with Divisor'Last every quotient is 1, so the sum is Length <= Limit
      pragma Assert (for all I in Index => Quotient (Values (I), Divisor'Last) = 1);
      return Divisor'Last;
   end Smallest_Divisor;
end Find_The_Smallest_Divisor;
