pragma SPARK_Mode (On);

package Sum_Digits_Convert is
   --  A bounded decimal conversion stub, limited to four digits.
   subtype Number is Natural range 0 .. 9_999;
   subtype Digit_Sum is Natural range 0 .. 36;

   function Sum_Digits (Value : Number) return Digit_Sum
     with Global => null;
end Sum_Digits_Convert;
