pragma Ada_2022;

package body Reverse_String with SPARK_Mode => On is
   function Reverse_Text (Input : Text_Array) return Text_Array is
   begin
      return [Input (6), Input (5), Input (4), Input (3), Input (2), Input (1)];
   end Reverse_Text;
end Reverse_String;
