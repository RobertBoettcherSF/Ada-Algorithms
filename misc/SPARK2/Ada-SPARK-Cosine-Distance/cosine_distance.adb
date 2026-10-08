pragma Ada_2022;
package body Cosine_Distance with SPARK_Mode => On is
   function Distance (A, B : Vector) return Integer is
      Dot : constant Integer := Integer (A (1)) * Integer (B (1))
        + Integer (A (2)) * Integer (B (2))
        + Integer (A (3)) * Integer (B (3));
      Norm_A : constant Integer := Integer (A (1)) * Integer (A (1))
        + Integer (A (2)) * Integer (A (2))
        + Integer (A (3)) * Integer (A (3));
      Norm_B : constant Integer := Integer (B (1)) * Integer (B (1))
        + Integer (B (2)) * Integer (B (2))
        + Integer (B (3)) * Integer (B (3));
      Denominator : constant Integer := Norm_A * Norm_B;
      Squared_Dot : constant Integer := Dot * Dot;
   begin
      -- This is the squared cosine distance, scaled by 1000.
      return (if Denominator = 0 then 0
              else 1000 - (1000 * Squared_Dot) / Denominator);
   end Distance;
end Cosine_Distance;
