pragma SPARK_Mode (On);

package body Multiply_Strings is
   function Multiply (Left, Right : Number) return Product is
   begin
      return Product (Left * Right);
   end Multiply;
end Multiply_Strings;
