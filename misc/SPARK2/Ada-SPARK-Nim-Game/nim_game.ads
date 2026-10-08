pragma SPARK_Mode (On);

package Nim_Game is
   subtype Stones is Natural range 0 .. 1_000_000_000;

   function Winning_Position (Pile : Stones) return Boolean
     with Global => null;
end Nim_Game;
