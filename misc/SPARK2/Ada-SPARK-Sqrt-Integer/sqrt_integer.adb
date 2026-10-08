pragma Ada_2022;
package body Sqrt_Integer with SPARK_Mode => On is
   function Floor_Sqrt (N : Number) return Root is
   begin
      case N is
         when 0 => return 0;
         when 1 .. 3 => return 1;
         when 4 .. 8 => return 2;
         when 9 .. 15 => return 3;
         when 16 .. 24 => return 4;
         when 25 .. 35 => return 5;
         when 36 .. 48 => return 6;
         when 49 .. 63 => return 7;
         when 64 .. 80 => return 8;
         when 81 .. 99 => return 9;
         when 100 => return 10;
      end case;
   end Floor_Sqrt;
end Sqrt_Integer;
