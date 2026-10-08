pragma SPARK_Mode (On);

package Encode_And_Decode_TinyURL_Stub is
   subtype Url_Id is Natural range 0 .. 255;
   subtype Short_Code is Positive range 1 .. 256;

   function Encode (Url : Url_Id) return Short_Code
     with Global => null;
   function Decode (Code : Short_Code) return Url_Id
     with Global => null;
end Encode_And_Decode_TinyURL_Stub;
