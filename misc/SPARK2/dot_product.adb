pragma Ada_2022;
package body Dot_Product with SPARK_Mode => On is
   function Product (A, B : Vector) return Integer is
   begin
      return Integer (A (1)) * Integer (B (1))
        + Integer (A (2)) * Integer (B (2))
        + Integer (A (3)) * Integer (B (3));
   end Product;
end Dot_Product;
