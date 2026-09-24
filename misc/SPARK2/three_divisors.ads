pragma SPARK_Mode (On);

package Three_Divisors is
   subtype Number is Natural range 0 .. 1_000_000;

   function Has_Three_Divisors (Value : Number) return Boolean
     with Global => null;
end Three_Divisors;
