pragma Ada_2022;
package Kth_Smallest_Matrix with SPARK_Mode => On is
   Matrix_Size : constant := 8;
   subtype Dimension is Positive range 1 .. Matrix_Size;
   subtype Rank is Positive range 1 .. Matrix_Size * Matrix_Size;
   subtype Value is Integer range 0 .. 1_000;
   type Matrix is array (Dimension, Dimension) of Value;
   type Kth_Result is record
      Kth    : Value;     --  the K-th smallest entry of the N x N block
      Probes : Natural;   --  comparisons of an entry with something
   end record;
   function Kth (M : Matrix; N : Dimension; K : Rank) return Kth_Result
     with Pre => K <= N * N;
end Kth_Smallest_Matrix;
