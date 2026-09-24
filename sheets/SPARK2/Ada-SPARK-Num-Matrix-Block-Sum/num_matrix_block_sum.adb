pragma Ada_2022;
package body Num_Matrix_Block_Sum with SPARK_Mode => On is
   function In_Block (R, C, Row, Col : Natural; K : Natural) return Boolean is
   begin
      return ((R >= Row and then R - Row <= K) or else (Row >= R and then Row - R <= K))
        and then ((C >= Col and then C - Col <= K) or else (Col >= C and then Col - C <= K));
   end In_Block;
   subtype Contribution_Value is Cell;
   function Contribution (A : Matrix; R, C, Row, Col : Natural; K : Natural) return Contribution_Value is
   begin
      if In_Block (R, C, Row, Col, K) then
         return A (Index (R), Index (C));
      else
         return 0;
      end if;
   end Contribution;

   function Block_Sum (A : Matrix; Row, Col : Index; K : Radius) return Long_Long_Integer is
   begin
      return Long_Long_Integer (Contribution (A, 1, 1, Row, Col, K)) + Long_Long_Integer (Contribution (A, 1, 2, Row, Col, K)) + Long_Long_Integer (Contribution (A, 1, 3, Row, Col, K)) + Long_Long_Integer (Contribution (A, 1, 4, Row, Col, K)) + Long_Long_Integer (Contribution (A, 2, 1, Row, Col, K)) + Long_Long_Integer (Contribution (A, 2, 2, Row, Col, K)) + Long_Long_Integer (Contribution (A, 2, 3, Row, Col, K)) + Long_Long_Integer (Contribution (A, 2, 4, Row, Col, K)) + Long_Long_Integer (Contribution (A, 3, 1, Row, Col, K)) + Long_Long_Integer (Contribution (A, 3, 2, Row, Col, K)) + Long_Long_Integer (Contribution (A, 3, 3, Row, Col, K)) + Long_Long_Integer (Contribution (A, 3, 4, Row, Col, K)) + Long_Long_Integer (Contribution (A, 4, 1, Row, Col, K)) + Long_Long_Integer (Contribution (A, 4, 2, Row, Col, K)) + Long_Long_Integer (Contribution (A, 4, 3, Row, Col, K)) + Long_Long_Integer (Contribution (A, 4, 4, Row, Col, K));
   end Block_Sum;
end Num_Matrix_Block_Sum;
