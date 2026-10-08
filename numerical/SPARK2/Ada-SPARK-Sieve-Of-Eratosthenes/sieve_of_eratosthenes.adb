pragma Ada_2022;
package body Sieve_Of_Eratosthenes with SPARK_Mode => On is
   function Is_Prime (N : Number) return Boolean is
      Divisor : Integer := 2;
   begin
      if N < 2 then
         return False;
      end if;
      while Divisor <= N / Divisor loop
         pragma Loop_Invariant (Divisor >= 2);
         pragma Loop_Variant (Decreases => N - Divisor);
         if N mod Divisor = 0 then
            return False;
         end if;
         Divisor := Divisor + 1;
      end loop;
      return True;
   end Is_Prime;

   procedure Sieve (Result : out Flags) is
   begin
      for N in Number loop
         Result (N) := Is_Prime (N);
      end loop;
   end Sieve;
end Sieve_Of_Eratosthenes;
