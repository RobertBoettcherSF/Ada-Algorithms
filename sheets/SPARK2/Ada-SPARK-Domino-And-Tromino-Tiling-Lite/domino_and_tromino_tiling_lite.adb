pragma Ada_2022;
package body Domino_And_Tromino_Tiling_Lite with SPARK_Mode => On is
   function Number_Of_Tilings (Columns : Column_Count) return Tiling_Count is
   begin
      case Columns is
         when 0 => return 1;
         when 1 => return 1;
         when 2 => return 2;
         when 3 => return 5;
         when 4 => return 11;
         when 5 => return 24;
         when 6 => return 53;
         when 7 => return 117;
         when 8 => return 258;
         when 9 => return 569;
         when 10 => return 1_255;
         when 11 => return 2_768;
         when 12 => return 6_105;
         when 13 => return 13_465;
         when 14 => return 29_698;
         when 15 => return 65_501;
         when 16 => return 144_467;
      end case;
   end Number_Of_Tilings;
end Domino_And_Tromino_Tiling_Lite;
