pragma Ada_2022;
package body Trapezoidal_Rule with SPARK_Mode => On is
   function Integrate (Steps : Steps_Count) return Integer is
      Numerator : constant Integer :=
        3 * Steps * Steps + (Steps - 1) * Steps * (2 * Steps - 1);
   begin
      -- Closed form of the bounded trapezoidal accumulation for x squared.
      return Numerator / (6 * Steps);
   end Integrate;
end Trapezoidal_Rule;
