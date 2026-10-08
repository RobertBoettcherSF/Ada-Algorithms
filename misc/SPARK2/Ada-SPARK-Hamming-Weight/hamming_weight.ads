pragma SPARK_Mode (On);

package Hamming_Weight is
   subtype Input is Natural range 0 .. 1_000_000_000;
   subtype Count is Natural range 0 .. 32;

   function Weight (Value : Input) return Count
     with Global => null;
end Hamming_Weight;
