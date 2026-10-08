pragma Ada_2022;
package body House_Robber_III_Lite with SPARK_Mode => On is
   function Max_Loot (Houses : House_Count) return Loot is
   begin
      case Houses is
         when 0 => return 0;
         when 1 | 2 => return 1;
         when 3 | 4 => return 2;
         when 5 | 6 => return 3;
         when 7 | 8 => return 4;
         when 9 | 10 => return 5;
         when 11 | 12 => return 6;
         when 13 | 14 => return 7;
         when 15 | 16 => return 8;
      end case;
   end Max_Loot;
end House_Robber_III_Lite;
