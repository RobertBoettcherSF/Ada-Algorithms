pragma SPARK_Mode (On);

package Decode_Ways is
   subtype Input is Positive range 1 .. 32;
   subtype Digit is Natural range 0 .. 9;
   subtype Result is Natural range 0 .. 1_000_000;
   type Digit_Sequence is array (Input) of Digit;

   function Count (Data : Digit_Sequence; Length : Input) return Result;
end Decode_Ways;
