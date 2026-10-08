pragma Ada_2022;
package body Bray_Curtis with SPARK_Mode => On is
   function Distance (A, B : Vector) return Integer is
      Numerator : constant Integer := abs (Integer (A (1)) - Integer (B (1)))
        + abs (Integer (A (2)) - Integer (B (2)))
        + abs (Integer (A (3)) - Integer (B (3)));
      Denominator : constant Integer := Integer (A (1)) + Integer (B (1))
        + Integer (A (2)) + Integer (B (2))
        + Integer (A (3)) + Integer (B (3));
   begin
      return (if Denominator = 0 then 0 else (100 * Numerator) / Denominator);
   end Distance;
end Bray_Curtis;
