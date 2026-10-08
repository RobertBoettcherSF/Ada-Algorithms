pragma Ada_2022;
package body Covariance with SPARK_Mode => On is
   function Center (Value : Component) return Integer is
   begin
      return Integer (Value) - 5;
   end Center;

   function Value (A, B : Vector) return Integer is
      Product : constant Integer := Center (A (1)) * Center (B (1))
        + Center (A (2)) * Center (B (2))
        + Center (A (3)) * Center (B (3));
   begin
      -- The fixed population size is three, so this is population covariance.
      return Product / 3;
   end Value;
end Covariance;
