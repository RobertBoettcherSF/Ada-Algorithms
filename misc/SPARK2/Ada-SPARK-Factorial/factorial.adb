pragma SPARK_Mode (On);

package body Factorial is
   function Compute (N : Input) return Result is
   begin
      case N is
         when 0 => return 1;
         when 1 => return 1;
         when 2 => return 2;
         when 3 => return 6;
         when 4 => return 24;
         when 5 => return 120;
         when 6 => return 720;
         when 7 => return 5_040;
         when 8 => return 40_320;
         when 9 => return 362_880;
         when 10 => return 3_628_800;
         when 11 => return 39_916_800;
         when 12 => return 479_001_600;
      end case;
   end Compute;
end Factorial;
