pragma Ada_2022;
package Knight_Probability_In_Chessboard_Lite with SPARK_Mode => On is
   subtype Move_Count is Natural range 0 .. 16;
   subtype Percent is Natural range 0 .. 100;
   function Survival_Percent (Moves : Move_Count) return Percent with Global => null;
end Knight_Probability_In_Chessboard_Lite;
