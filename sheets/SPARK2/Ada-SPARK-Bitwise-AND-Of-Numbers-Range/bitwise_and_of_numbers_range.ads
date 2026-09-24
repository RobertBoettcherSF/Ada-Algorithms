pragma Ada_2022;
package Bitwise_AND_Of_Numbers_Range with SPARK_Mode => On is
   type Byte is mod 256;
   subtype Input is Byte range 0 .. 32;

   function And_Range (Left, Right : Input) return Byte
     with Pre => Left <= Right, Global => null;
end Bitwise_AND_Of_Numbers_Range;
