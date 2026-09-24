pragma Ada_2022;
package Count_Primes with SPARK_Mode => On is
   subtype Limit is Natural range 0 .. 30;
   subtype Prime_Count is Natural range 0 .. 10;
   function Count_Primes_Below (N : Limit) return Prime_Count
     with Global => null;
end Count_Primes;
