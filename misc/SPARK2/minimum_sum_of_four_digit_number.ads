pragma SPARK_Mode (On);

package Minimum_Sum_Of_Four_Digit_Number is
   subtype Digit is Natural range 0 .. 9;
   subtype Sum is Natural range 0 .. 198;

   function Minimum_Sum
     (A, B, C, D : Digit) return Sum
     with Global => null,
          Post => Minimum_Sum'Result <= Sum'Last;
end Minimum_Sum_Of_Four_Digit_Number;
