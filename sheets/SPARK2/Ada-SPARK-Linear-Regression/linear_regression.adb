pragma Ada_2022;
package body Linear_Regression with SPARK_Mode => On is
   function Predict (Y1, Y2, Y3, Y4 : Observation; X : Input) return Integer is
      Mean  : constant Integer := (Y1 + Y2 + Y3 + Y4) / 4;
      Slope : constant Integer := (-3 * Y1 - Y2 + Y3 + 3 * Y4) / 10;
   begin
      -- The fixed x coordinates are 1, 2, 3, and 4.
      return (2 * Mean + Slope * (2 * X - 5)) / 2;
   end Predict;
end Linear_Regression;
