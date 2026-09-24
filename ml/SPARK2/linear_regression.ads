pragma Ada_2022;
package Linear_Regression with SPARK_Mode => On is
   subtype Observation is Integer range -100 .. 100;
   subtype Input is Integer range 1 .. 4;
   function Predict (Y1, Y2, Y3, Y4 : Observation; X : Input) return Integer
     with Global => null;
end Linear_Regression;
