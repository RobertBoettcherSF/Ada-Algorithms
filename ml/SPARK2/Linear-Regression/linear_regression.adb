pragma Ada_2022;
package body Linear_Regression with SPARK_Mode => On is
   --  Least-squares line through (1, Y1) .. (4, Y4): mean S / 4 and slope T / 10 with
   --  S = Y1 + Y2 + Y3 + Y4 and T = -3 Y1 - Y2 + Y3 + 3 Y4, so the prediction at X is
   --  (5 S + T (2 X - 5)) / 20, kept as one fraction and truncated toward zero once.
   function Predict (Y1, Y2, Y3, Y4 : Observation; X : Input) return Integer is
      S : constant Integer range -400 .. 400 := Y1 + Y2 + Y3 + Y4;
      T : constant Integer range -800 .. 800 := -3 * Y1 - Y2 + Y3 + 3 * Y4;
   begin
      return (5 * S + T * (2 * X - 5)) / 20;
   end Predict;
end Linear_Regression;
