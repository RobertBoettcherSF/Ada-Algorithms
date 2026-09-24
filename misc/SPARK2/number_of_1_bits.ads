pragma SPARK_Mode (On);

package Number_Of_1_Bits is
   subtype Input is Natural range 0 .. 1_000_000_000;
   subtype Count is Natural range 0 .. 32;

   function Count_Ones (Value : Input) return Count
     with Global => null;
end Number_Of_1_Bits;
