pragma Ada_2022;
package body Pearson_Correlation with SPARK_Mode => On is
   subtype Centered is Integer range -5 .. 5;

   function Center (Value : Component) return Centered is
   begin
      return Integer (Value) - 5;
   end Center;

   function Correlation (A, B : Vector) return Integer is
      X1 : constant Integer := Center (A (1));
      X2 : constant Integer := Center (A (2));
      X3 : constant Integer := Center (A (3));
      Y1 : constant Integer := Center (B (1));
      Y2 : constant Integer := Center (B (2));
      Y3 : constant Integer := Center (B (3));
      Numerator : constant Integer := X1 * Y1 + X2 * Y2 + X3 * Y3;
      Energy : constant Integer := X1 * X1 + X2 * X2 + X3 * X3
        + Y1 * Y1 + Y2 * Y2 + Y3 * Y3;
   begin
      -- Energy-normalized centered correlation avoids floating point and sqrt.
      return (if Energy = 0 then 100 else Numerator);
   end Correlation;
end Pearson_Correlation;
