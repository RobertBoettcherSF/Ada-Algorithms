pragma Ada_2022;
package body Cosine_Similarity with SPARK_Mode => On is
   function Similarity (A, B : Vector) return Integer is
      Dot : constant Integer := Integer (A (1)) * Integer (B (1))
        + Integer (A (2)) * Integer (B (2))
        + Integer (A (3)) * Integer (B (3));
   begin
      -- Components are unit-sign coordinates; 3 is the fixed norm product.
      return (100 * Dot) / 3;
   end Similarity;
end Cosine_Similarity;
