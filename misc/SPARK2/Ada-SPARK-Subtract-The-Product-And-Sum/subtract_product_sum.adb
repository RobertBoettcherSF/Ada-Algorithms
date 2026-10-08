pragma SPARK_Mode (On);

package body Subtract_Product_Sum is
   function Difference (Value : Number) return Result is
      Tens : Natural range 0 .. 9 := Value / 10;
      Ones : Natural range 0 .. 9 := Value mod 10;
   begin
      return Tens * Ones - Tens - Ones;
   end Difference;
end Subtract_Product_Sum;
