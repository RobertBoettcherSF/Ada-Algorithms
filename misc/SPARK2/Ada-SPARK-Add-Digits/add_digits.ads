pragma SPARK_Mode (On);

package Add_Digits is
   subtype Input is Natural range 0 .. 1_000_000_000;
   subtype Digit is Natural range 0 .. 9;

   function Digital_Root (Value : Input) return Digit
     with Global => null;
end Add_Digits;
