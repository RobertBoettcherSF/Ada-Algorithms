pragma Ada_2022;

package body Int_To_Roman_Stub with SPARK_Mode => On is
   function To_Roman (Number : Number_Type) return Roman_Text is
   begin
      case Number is
         when 1 => return "I       ";
         when 2 => return "II      ";
         when 3 => return "III     ";
         when 4 => return "IV      ";
         when 5 => return "V       ";
         when 6 => return "VI      ";
         when 7 => return "VII     ";
         when 8 => return "VIII    ";
         when 9 => return "IX      ";
         when 10 => return "X       ";
         when 11 => return "XI      ";
         when 12 => return "XII     ";
         when 13 => return "XIII    ";
         when 14 => return "XIV     ";
         when 15 => return "XV      ";
         when 16 => return "XVI     ";
         when 17 => return "XVII    ";
         when 18 => return "XVIII   ";
         when 19 => return "XIX     ";
         when 20 => return "XX      ";
      end case;
   end To_Roman;
end Int_To_Roman_Stub;
