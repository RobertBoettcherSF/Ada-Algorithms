pragma Ada_2022;
package Count_Primes with SPARK_Mode => On is
   --  N up to 10**7: the sieve is a packed Boolean array of 10**7 + 1 bits
   --  (about 1.25 MB), local to the call, so it fits an ordinary 8 MB stack
   --  with room to spare (no Storage_Error on a plain run). The bound is
   --  memory, not arithmetic: I * I and J + I stay below 10**7.
   Max_Limit : constant := 10**7;
   subtype Limit is Natural range 0 .. Max_Limit;
   subtype Prime_Count is Natural range 0 .. Max_Limit;

   --  Number of primes P < N, by the sieve of Eratosthenes.
   --  The Post only bounds the result; the functional Post (Result = number
   --  of primes below N) is not proved yet: see H167 in tools/vv/handover.csv.
   function Count_Primes_Below (N : Limit) return Prime_Count
     with Global => null,
          Post   => Count_Primes_Below'Result <= N;
end Count_Primes;
