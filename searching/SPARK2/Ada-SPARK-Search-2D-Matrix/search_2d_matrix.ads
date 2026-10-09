pragma Ada_2022;

--  Search a matrix that is sorted in row-major order (each row
--  non-decreasing, and each row starts no lower than the previous one
--  ends): treat the 64 cells as one sorted array and halve it.
package Search_2D_Matrix with SPARK_Mode => On is
   Rows  : constant := 8;
   Cols  : constant := 8;
   Cells : constant := Rows * Cols;
   subtype Row is Positive range 1 .. Rows;
   subtype Column is Positive range 1 .. Cols;
   subtype Cell_Index is Positive range 1 .. Cells;
   subtype Value is Integer range 0 .. 99;
   type Matrix is array (Row, Column) of Value;

   --  The K-th cell in row-major order.
   function Row_Of (K : Cell_Index) return Row is ((K - 1) / Cols + 1);
   function Column_Of (K : Cell_Index) return Column is ((K - 1) mod Cols + 1);
   function Cell (M : Matrix; K : Cell_Index) return Value is
     (M (Row_Of (K), Column_Of (K)));

   subtype Sorted_Matrix is Matrix
     with Dynamic_Predicate =>
       (for all K in 1 .. Cells - 1 => Cell (Sorted_Matrix, K) <= Cell (Sorted_Matrix, K + 1));

   --  Cell (M, Position_Of (R, C)) is M (R, C): the cells are exactly
   --  the matrix entries, so a statement about every cell is one about
   --  every entry.
   function Position_Of (R : Row; C : Column) return Cell_Index is ((R - 1) * Cols + C)
   with Post => Row_Of (Position_Of'Result) = R and then Column_Of (Position_Of'Result) = C;

   --  65 insertion points: at most 7 comparisons, plus 1 for the cell
   --  found.
   subtype Probe_Count is Natural range 0 .. 8;
   type Search_Result is record
      Found  : Boolean;       --  some cell equals Target
      Probes : Probe_Count;   --  comparisons with cells
   end record;

   function Contains (Input : Sorted_Matrix; Target : Value) return Search_Result
   with
     Global => null,
     Post   => Contains'Result.Found = (for some K in Cell_Index => Cell (Input, K) = Target);
end Search_2D_Matrix;
