pragma Ada_2022;
package body Base64_Encode with SPARK_Mode => On is
   function Encoded_Length (Length : Input_Length) return Natural is
   begin
      return ((Length + 2) / 3) * 4;
   end Encoded_Length;
end Base64_Encode;
