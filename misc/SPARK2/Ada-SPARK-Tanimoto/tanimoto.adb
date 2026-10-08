pragma Ada_2022;
package body Tanimoto with SPARK_Mode => On is
   function Similarity (A, B : Vector) return Integer is
      Dot : constant Integer := Integer (A (1)) * Integer (B (1))
        + Integer (A (2)) * Integer (B (2))
        + Integer (A (3)) * Integer (B (3));
      Norm_A : constant Integer := Integer (A (1)) * Integer (A (1))
        + Integer (A (2)) * Integer (A (2))
        + Integer (A (3)) * Integer (A (3));
      Norm_B : constant Integer := Integer (B (1)) * Integer (B (1))
        + Integer (B (2)) * Integer (B (2))
        + Integer (B (3)) * Integer (B (3));
      Denominator : constant Integer := Norm_A + Norm_B - Dot;
   begin
      return (if Denominator = 0 then 100 else (100 * Dot) / Denominator);
   end Similarity;
end Tanimoto;
