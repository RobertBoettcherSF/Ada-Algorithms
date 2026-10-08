pragma Ada_2022;
package Base64_Decode with SPARK_Mode => On is
   Max_Encoded_Length : constant := 64;
   subtype Encoded_Length is Natural range 0 .. Max_Encoded_Length;

   function Decoded_Length (Length : Encoded_Length) return Natural
     with
       Global => null,
       Post => Decoded_Length'Result <= 48;
end Base64_Decode;
