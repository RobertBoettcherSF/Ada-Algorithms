pragma SPARK_Mode (On);

package Tic_Tac_Toe_Stub is
   Board_Size : constant := 3;
   subtype Coordinate is Positive range 1 .. Board_Size;
   type Player is (Empty, X, O);
   type Board is array (Coordinate, Coordinate) of Player;

   function Winner (B : Board) return Player with Global => null;
end Tic_Tac_Toe_Stub;
