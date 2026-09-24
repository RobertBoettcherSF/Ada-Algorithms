pragma Ada_2022;
package body Dice_Coefficient with SPARK_Mode => On is
   function Similarity (A, B : Vector) return Integer is
      Intersection : constant Integer := Integer (A (1)) * Integer (B (1))
        + Integer (A (2)) * Integer (B (2))
        + Integer (A (3)) * Integer (B (3));
      Cardinality : constant Integer := Integer (A (1)) + Integer (A (2))
        + Integer (A (3)) + Integer (B (1)) + Integer (B (2))
        + Integer (B (3));
   begin
      -- The empty-set convention gives identical empty vectors full similarity.
      return (if Cardinality = 0 then 100
              else (200 * Intersection) / Cardinality);
   end Similarity;
end Dice_Coefficient;
