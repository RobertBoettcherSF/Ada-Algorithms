pragma Ada_2022;
package body Canberra_Distance with SPARK_Mode => On is
   function Term (A, B : Component) return Integer is
      Denominator : constant Integer := Integer (A) + Integer (B);
      Difference : constant Integer := abs (Integer (A) - Integer (B));
   begin
      return (if Denominator = 0 then 0
              else (1000 * Difference) / Denominator);
   end Term;

   function Distance (A, B : Vector) return Integer is
   begin
      return Term (A (1), B (1)) + Term (A (2), B (2)) + Term (A (3), B (3));
   end Distance;
end Canberra_Distance;
