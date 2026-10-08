pragma SPARK_Mode (On);

package Decode_String_Stub is
   subtype Repeat_Count is Positive range 1 .. 3;
   subtype Unit_Length is Positive range 1 .. 4;
   subtype Decoded_Length is Positive range 1 .. 12;

   function Length_Of (Repeat : Repeat_Count; Unit : Unit_Length)
     return Decoded_Length
     with Global => null;
end Decode_String_Stub;
