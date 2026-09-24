pragma Ada_2022;
package body Climbing_Stairs with SPARK_Mode => On is
   function Count (N : Steps) return Ways is
   begin
      case N is
         when 0 | 1 => return 1;
         when 2 => return 2;
         when 3 => return 3;
         when 4 => return 5;
         when 5 => return 8;
         when 6 => return 13;
         when 7 => return 21;
         when 8 => return 34;
         when 9 => return 55;
         when 10 => return 89;
      end case;
   end Count;
end Climbing_Stairs;
