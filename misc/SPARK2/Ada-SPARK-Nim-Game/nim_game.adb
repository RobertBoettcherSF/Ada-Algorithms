pragma SPARK_Mode (On);

package body Nim_Game is
   function Winning_Position (Pile : Stones) return Boolean is
   begin
      return Pile mod 4 /= 0;
   end Winning_Position;
end Nim_Game;
