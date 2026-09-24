pragma Ada_2022;
package Decode_Ways_Stub with SPARK_Mode => On is
   subtype Position is Positive range 1 .. 6;
   subtype Digit is Natural range 0 .. 9;
   type Digit_Seq is array (Position) of Digit;
   subtype Ways is Natural range 0 .. 64;
   function Count (D : Digit_Seq) return Ways with Global => null;
end Decode_Ways_Stub;
