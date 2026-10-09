pragma Ada_2022;
package Count_Primes with SPARK_Mode => On is
   Max_Limit : constant := 1_000;
   subtype Limit is Natural range 0 .. Max_Limit;
   subtype Prime_Count is Natural range 0 .. Max_Limit;

   --  Number of primes P < N, by the sieve of Eratosthenes.
   --  The Post only bounds the result; the functional Post (Result = number
   --  of primes below N) is not proved yet: see H167 in tools/vv/handover.csv.
   function Count_Primes_Below (N : Limit) return Prime_Count
     with Global => null,
          Post   => Count_Primes_Below'Result <= N;
end Count_Primes;
