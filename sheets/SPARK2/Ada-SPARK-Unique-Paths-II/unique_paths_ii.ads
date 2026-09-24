pragma SPARK_Mode (On);

package Unique_Paths_II is
   subtype Dimension is Positive range 1 .. 8;
   subtype Result is Natural range 0 .. 1_000_000;
   type Grid is array (Dimension, Dimension) of Boolean;

   function Count (Rows : Dimension; Cols : Dimension; Blocked : Grid) return Result;
end Unique_Paths_II;
