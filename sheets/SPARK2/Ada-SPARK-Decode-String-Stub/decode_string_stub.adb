pragma SPARK_Mode (On);

package body Decode_String_Stub is
   function Length_Of (Repeat : Repeat_Count; Unit : Unit_Length)
     return Decoded_Length is
   begin
      return Decoded_Length (Repeat * Unit);
   end Length_Of;
end Decode_String_Stub;
