pragma SPARK_Mode (On);

package body Prime_Check is
   function Is_Prime (N : Input) return Boolean is
   begin
      for Divisor in 2 .. 32 loop
         if Divisor * Divisor <= N and then N mod Divisor = 0 then
            return False;
         end if;
      end loop;
      return True;
   end Is_Prime;
end Prime_Check;
