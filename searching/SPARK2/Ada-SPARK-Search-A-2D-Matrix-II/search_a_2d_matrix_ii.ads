pragma Ada_2022;

--  Search a matrix whose rows and columns never decrease (left to right,
--  top to bottom) by walking a staircase from the top-right corner.
package Search_A_2D_Matrix_II with SPARK_Mode => On is
   Rows  : constant := 8;
   Cols  : constant := 8;
   Cells : constant := Rows * Cols;
   subtype Row is Positive range 1 .. Rows;
   subtype Column is Positive range 1 .. Cols;
   subtype Cell_Index is Positive range 1 .. Cells;
   subtype Value is Integer range 0 .. 100;
   type Matrix is array (Row, Column) of Value;

   --  The K-th cell in row-major order. The predicate and the
   --  postcondition are stated over K (one quantifier each).
   function Row_Of (K : Cell_Index) return Row is ((K - 1) / Cols + 1);
   function Column_Of (K : Cell_Index) return Column is ((K - 1) mod Cols + 1);
   function Cell (M : Matrix; K : Cell_Index) return Value is
     (M (Row_Of (K), Column_Of (K)));

   --  Cell (M, Position_Of (R, C)) is M (R, C): the cells are exactly
   --  the matrix entries.
   function Position_Of (R : Row; C : Column) return Cell_Index is ((R - 1) * Cols + C)
   with Post => Row_Of (Position_Of'Result) = R and then Column_Of (Position_Of'Result) = C;

   --  Each entry is <= its right neighbour (K + 1, same row) and <= the
   --  entry below it (K + Cols, same column).
   subtype Staircase_Matrix is Matrix
     with Dynamic_Predicate =>
       (for all K in Cell_Index =>
          (if Column_Of (K) < Cols then Cell (Staircase_Matrix, K) <= Cell (Staircase_Matrix, K + 1))
          and then
          (if Row_Of (K) < Rows then Cell (Staircase_Matrix, K) <= Cell (Staircase_Matrix, K + Cols)));

   --  Each comparison drops a row or a column, or ends the search.
   subtype Probe_Count is Natural range 0 .. Rows + Cols - 1;
   type Search_Result is record
      Found  : Boolean;       --  some cell equals Target
      Probes : Probe_Count;   --  comparisons with cells (a three-way one counts once)
   end record;

   function Contains (Grid : Staircase_Matrix; Target : Value) return Search_Result
   with
     Global => null,
     Post   => Contains'Result.Found = (for some K in Cell_Index => Cell (Grid, K) = Target);
end Search_A_2D_Matrix_II;
