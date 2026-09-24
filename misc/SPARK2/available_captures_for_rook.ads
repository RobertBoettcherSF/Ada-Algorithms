pragma Ada_2022;
package Available_Captures_For_Rook with SPARK_Mode => On is
   Side : constant := 4;
   subtype Index is Positive range 1 .. Side;
   type Square is (Empty, Rook, Bishop, Pawn);
   type Board is array (Index, Index) of Square;
   function Count_Captures (Position : Index; Layout : Board) return Natural;
end Available_Captures_For_Rook;
