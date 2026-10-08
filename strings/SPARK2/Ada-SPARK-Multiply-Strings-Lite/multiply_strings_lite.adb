pragma Ada_2022;

package body Multiply_Strings_Lite with SPARK_Mode => On is
   function Multiply (Left : Digit; Right : Digit) return Product is
   begin
      return Left * Right;
   end Multiply;
end Multiply_Strings_Lite;
