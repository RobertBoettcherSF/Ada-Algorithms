pragma SPARK_Mode (On);

package body Encode_And_Decode_TinyURL_Stub is
   function Encode (Url : Url_Id) return Short_Code is
   begin
      return Short_Code (Url + 1);
   end Encode;

   function Decode (Code : Short_Code) return Url_Id is
   begin
      return Url_Id (Code - 1);
   end Decode;
end Encode_And_Decode_TinyURL_Stub;
