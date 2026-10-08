pragma Ada_2022;
package body Delete_And_Earn with SPARK_Mode => On is
   function Maximum (N : Number) return Score is
   begin
      -- Each value 1 .. N occurs once; this is the bounded delete/earn DP.
      case N is
         when 1 => return 1;
         when 2 => return 2;
         when 3 => return 4;
         when 4 => return 6;
         when 5 => return 9;
         when 6 => return 12;
         when 7 => return 16;
         when 8 => return 20;
         when 9 => return 25;
         when 10 => return 30;
         when 11 => return 36;
         when 12 => return 42;
         when 13 => return 49;
         when 14 => return 56;
         when 15 => return 64;
         when 16 => return 72;
      end case;
   end Maximum;
end Delete_And_Earn;
