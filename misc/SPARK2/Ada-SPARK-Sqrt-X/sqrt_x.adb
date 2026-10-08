pragma Ada_2022;
package body Sqrt_X with SPARK_Mode => On is
   function Floor_Sqrt (N : Number) return Root is
      Result : Root;
   begin
      case N is
         when 0 => Result := 0;
         when 1 .. 3 => Result := 1;
         when 4 .. 8 => Result := 2;
         when 9 .. 15 => Result := 3;
         when 16 .. 24 => Result := 4;
         when 25 .. 35 => Result := 5;
         when 36 .. 48 => Result := 6;
         when 49 .. 63 => Result := 7;
         when 64 .. 80 => Result := 8;
         when 81 .. 99 => Result := 9;
         when 100 => Result := 10;
      end case;
      pragma Assert (Result <= 10);
      return Result;
   end Floor_Sqrt;
end Sqrt_X;
