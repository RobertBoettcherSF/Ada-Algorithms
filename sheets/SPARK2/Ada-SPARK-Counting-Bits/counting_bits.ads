pragma SPARK_Mode (On);

package Counting_Bits is
   subtype Input is Natural range 0 .. 1_000_000_000;
   subtype Count is Natural range 0 .. 32;

   function Ones (Value : Input) return Count
     with Global => null;
end Counting_Bits;
