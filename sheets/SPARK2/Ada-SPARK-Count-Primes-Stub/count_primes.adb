pragma SPARK_Mode (On);

package body Count_Primes is
   function Is_Prime (Value : Limit) return Boolean is
      Divisor : Integer := 2;
   begin
      if Value < 2 then
         return False;
      end if;
      while Divisor <= Value / Divisor loop
         pragma Loop_Invariant (Divisor >= 2);
         pragma Loop_Variant (Decreases => Value - Divisor);
         if Value mod Divisor = 0 then
            return False;
         end if;
         Divisor := Divisor + 1;
      end loop;
      return True;
   end Is_Prime;

   function Below (Value : Limit) return Count is
      Candidate : Integer := 2;
      Answer    : Integer := 0;
   begin
      while Candidate < Value loop
         pragma Loop_Invariant (Candidate >= 2);
         pragma Loop_Invariant (Answer >= 0);
         pragma Loop_Invariant (Answer < Candidate);
         pragma Loop_Variant (Decreases => Value - Candidate);
         if Is_Prime (Limit (Candidate)) then
            Answer := Answer + 1;
         end if;
         Candidate := Candidate + 1;
      end loop;
      return Count (Answer);
   end Below;
end Count_Primes;
