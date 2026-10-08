pragma Ada_2022;
package body Overlap_Coefficient with SPARK_Mode => On is
   function Minimum (A, B : Integer) return Integer is
   begin
      return (if A < B then A else B);
   end Minimum;

   function Similarity (A, B : Vector) return Integer is
      Intersection : constant Integer := Minimum (Integer (A (1)), Integer (B (1)))
        + Minimum (Integer (A (2)), Integer (B (2)))
        + Minimum (Integer (A (3)), Integer (B (3)));
      Sum_A : constant Integer := Integer (A (1)) + Integer (A (2)) + Integer (A (3));
      Sum_B : constant Integer := Integer (B (1)) + Integer (B (2)) + Integer (B (3));
      Denominator : constant Integer := Minimum (Sum_A, Sum_B);
   begin
      return (if Denominator = 0 then 100
              else (100 * Intersection) / Denominator);
   end Similarity;
end Overlap_Coefficient;
