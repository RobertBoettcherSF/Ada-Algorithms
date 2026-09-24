pragma SPARK_Mode (On);

package Reversed_Bits is
   type Byte is mod 256;

   function Reversed (Value : Byte) return Byte
     with Global => null;
end Reversed_Bits;
