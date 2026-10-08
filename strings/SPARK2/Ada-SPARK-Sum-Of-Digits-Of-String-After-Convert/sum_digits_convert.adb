pragma SPARK_Mode (On);

package body Sum_Digits_Convert is
   function Sum_Digits (Value : Number) return Digit_Sum is
      D0 : Natural range 0 .. 9 := Value mod 10;
      D1 : Natural range 0 .. 9 := (Value / 10) mod 10;
      D2 : Natural range 0 .. 9 := (Value / 100) mod 10;
      D3 : Natural range 0 .. 9 := (Value / 1_000) mod 10;
   begin
      return D0 + D1 + D2 + D3;
   end Sum_Digits;
end Sum_Digits_Convert;
