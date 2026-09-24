pragma Ada_2022;
package Base64_Encode with SPARK_Mode => On is
   Max_Input_Length : constant := 48;
   subtype Input_Length is Natural range 0 .. Max_Input_Length;

   function Encoded_Length (Length : Input_Length) return Natural
     with
       Global => null,
       Post => Encoded_Length'Result <= 64;
end Base64_Encode;
