pragma Ada_2022;
package body Count_Primes with SPARK_Mode => On is

   --  Sieve of Eratosthenes: walk I = 2, 3, ..., N - 1; an I not crossed
   --  out by a smaller prime is prime, and its multiples I * I, I * I + I,
   --  ... below N are crossed out (smaller multiples already are).
   function Count_Primes_Below (N : Limit) return Prime_Count is
      type Sieve is array (0 .. Max_Limit) of Boolean with Pack;   --  1.25 MB
      Composite : Sieve := [others => False];
      Count     : Prime_Count := 0;
      J         : Natural;
   begin
      for I in 2 .. N - 1 loop
         pragma Loop_Invariant (Count <= I - 2);
         if not Composite (I) then
            Count := Count + 1;
            if I <= (N - 1) / I then
               J := I * I;
               loop
                  pragma Loop_Invariant (J in I * I .. N - 1);
                  pragma Loop_Variant (Increases => J);
                  Composite (J) := True;
                  exit when J > N - 1 - I;
                  J := J + I;
               end loop;
            end if;
         end if;
      end loop;
      return Count;
   end Count_Primes_Below;
end Count_Primes;
