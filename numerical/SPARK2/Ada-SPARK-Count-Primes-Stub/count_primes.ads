pragma SPARK_Mode (On);

package Count_Primes is
   subtype Limit is Natural range 0 .. 100;
   subtype Count is Natural range 0 .. 100;

   function Is_Prime (Value : Limit) return Boolean
     with Global => null;

   function Below (Value : Limit) return Count
     with Global => null;
end Count_Primes;
