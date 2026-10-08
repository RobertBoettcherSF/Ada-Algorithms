pragma Ada_2022;

package body Count_And_Say_Stub with SPARK_Mode => On is
   function Describe (Number : Number_Type) return Text_Array is
   begin
      case Number is
         when 1 => return "1           ";
         when 2 => return "11          ";
         when 3 => return "21          ";
         when 4 => return "1211        ";
         when 5 => return "111221      ";
      end case;
   end Describe;
end Count_And_Say_Stub;
