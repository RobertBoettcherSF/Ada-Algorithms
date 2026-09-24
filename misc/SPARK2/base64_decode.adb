pragma Ada_2022;
package body Base64_Decode with SPARK_Mode => On is
   function Decoded_Length (Length : Encoded_Length) return Natural is
   begin
      return (Length / 4) * 3;
   end Decoded_Length;
end Base64_Decode;
