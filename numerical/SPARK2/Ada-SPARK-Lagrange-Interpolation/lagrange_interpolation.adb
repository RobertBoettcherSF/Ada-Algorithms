pragma Ada_2022;
package body Lagrange_Interpolation with SPARK_Mode => On is
   function Interpolate (Y0, Y1, Y2 : Value; X : Argument) return Integer is
      A : constant Integer := Y0 + Y2 - 2 * Y1;
      B : constant Integer := Y2 - Y0;
   begin
      -- The three samples are at -1, 0, and 1.
      return (A * X * X + B * X + 2 * Y1) / 2;
   end Interpolate;
end Lagrange_Interpolation;
