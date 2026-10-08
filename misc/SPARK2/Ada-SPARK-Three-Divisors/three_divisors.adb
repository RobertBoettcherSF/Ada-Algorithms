pragma SPARK_Mode (On);

package body Three_Divisors is
   subtype Root is Natural range 0 .. 1_000;

   function Is_Prime (Value : Root) return Boolean is
   begin
      if Value < 2 then
         return False;
      end if;
      for Divisor in 2 .. 31 loop
         if Value mod Divisor = 0 then
            return Value = Divisor;
         end if;
      end loop;
      return True;
   end Is_Prime;

   function Has_Three_Divisors (Value : Number) return Boolean is
   begin
      for Candidate in 2 .. 1_000 loop
         if Candidate * Candidate = Value then
            return Is_Prime (Candidate);
         end if;
      end loop;
      return False;
   end Has_Three_Divisors;
end Three_Divisors;
