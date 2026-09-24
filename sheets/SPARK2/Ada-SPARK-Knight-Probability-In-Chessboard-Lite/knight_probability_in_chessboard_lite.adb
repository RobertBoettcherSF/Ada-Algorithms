pragma Ada_2022;
package body Knight_Probability_In_Chessboard_Lite with SPARK_Mode => On is
   function Survival_Percent (Moves : Move_Count) return Percent is
   begin
      if Moves = 0 then
         return 100;
      else
         return 0;
      end if;
   end Survival_Percent;
end Knight_Probability_In_Chessboard_Lite;
