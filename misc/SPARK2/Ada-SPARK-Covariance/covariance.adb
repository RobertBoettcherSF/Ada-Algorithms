pragma Ada_2022;
package body Covariance with SPARK_Mode => On is
   function Value (A, B : Vector) return Integer is
      Sum_A : constant Integer := A (1) + A (2) + A (3);
      Sum_B : constant Integer := B (1) + B (2) + B (3);
      Sum_AB : constant Integer := A (1) * B (1) + A (2) * B (2) + A (3) * B (3);
   begin
      --  Population covariance: 1/3 * sum (A (I) - Sum_A / 3) * (B (I) - Sum_B / 3)
      --  = (3 * Sum_AB - Sum_A * Sum_B) / 9, truncated toward zero.
      return (3 * Sum_AB - Sum_A * Sum_B) / 9;
   end Value;
end Covariance;
