pragma SPARK_Mode (On);

package Palindrome_Number is
   subtype Input is Natural range 0 .. 1_000_000_000;

   function Is_Palindrome (Value : Input) return Boolean
     with Global => null;
end Palindrome_Number;
