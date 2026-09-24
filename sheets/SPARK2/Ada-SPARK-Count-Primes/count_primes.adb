pragma Ada_2022;
package body Count_Primes with SPARK_Mode => On is
   function Count_Primes_Below (N : Limit) return Prime_Count is
      Result : Prime_Count;
   begin
      case N is
         when 0 .. 2 => Result := 0;
         when 3 => Result := 1;
         when 4 .. 5 => Result := 2;
         when 6 .. 7 => Result := 3;
         when 8 .. 11 => Result := 4;
         when 12 .. 13 => Result := 5;
         when 14 .. 17 => Result := 6;
         when 18 .. 19 => Result := 7;
         when 20 .. 23 => Result := 8;
         when 24 .. 29 => Result := 9;
         when 30 => Result := 10;
      end case;
      pragma Assert (Result <= 10);
      return Result;
   end Count_Primes_Below;
end Count_Primes;
