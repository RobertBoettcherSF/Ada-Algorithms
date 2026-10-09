pragma Ada_2022;

--  K-th smallest entry of an N x N block whose rows and columns never
--  decrease: binary search on the value, counting the entries <= a
--  value with a staircase walk.
package Kth_Smallest_Matrix with SPARK_Mode => On is
   Matrix_Size : constant := 8;
   Cells       : constant := Matrix_Size * Matrix_Size;
   subtype Dimension is Positive range 1 .. Matrix_Size;
   subtype Rank is Positive range 1 .. Cells;
   subtype Cell_Index is Positive range 1 .. Cells;
   subtype Value is Integer range 0 .. 1_000;
   type Matrix is array (Dimension, Dimension) of Value;

   --  The K-th cell of the 8 x 8 matrix in row-major order.
   function Row_Of (K : Cell_Index) return Dimension is ((K - 1) / Matrix_Size + 1);
   function Column_Of (K : Cell_Index) return Dimension is ((K - 1) mod Matrix_Size + 1);
   function Cell (M : Matrix; K : Cell_Index) return Value is
     (M (Row_Of (K), Column_Of (K)));
   function Position_Of (R, C : Dimension) return Cell_Index is ((R - 1) * Matrix_Size + C)
   with Post => Row_Of (Position_Of'Result) = R and then Column_Of (Position_Of'Result) = C;

   --  Inside the N x N block each entry is <= its right neighbour
   --  (K + 1) and <= the entry below it (K + Matrix_Size).
   function Block_Sorted (M : Matrix; N : Dimension) return Boolean is
     (for all K in Cell_Index =>
        (if Row_Of (K) <= N and then Column_Of (K) < N then Cell (M, K) <= Cell (M, K + 1))
        and then
        (if Row_Of (K) < N and then Column_Of (K) <= N then Cell (M, K) <= Cell (M, K + Matrix_Size)));

   type Square is record
      N : Dimension;   --  the block is M (1 .. N, 1 .. N)
      M : Matrix;      --  entries outside the block are ignored
   end record;

   subtype Sorted_Square is Square
     with Dynamic_Predicate => Block_Sorted (Sorted_Square.M, Sorted_Square.N);

   --  Entries M (I, 1 .. J) that are <= X.
   function Row_Count (M : Matrix; I : Dimension; X : Integer; J : Natural) return Natural
   with
     Ghost,
     Pre                => J <= Matrix_Size,
     Post               => Row_Count'Result <= J,
     Subprogram_Variant => (Decreases => J);

   --  Entries of rows 1 .. I of the N x N block that are <= X.
   function Total (M : Matrix; N : Dimension; X : Integer; I : Natural) return Natural
   with
     Ghost,
     Pre                => I <= N,
     Post               => Total'Result <= Matrix_Size * I,
     Subprogram_Variant => (Decreases => I);

   --  Entries of the block that are <= X.
   function Count (S : Square; X : Integer) return Natural is (Total (S.M, S.N, X, S.N))
   with Ghost;

   --  At most 10 counts: the value range 0 .. 1000 halved.
   subtype Try_Count is Natural range 0 .. 10;
   --  Each count compares at most 2 * N entries with the value.
   subtype Probe_Count is Natural range 0 .. 10 * 2 * Matrix_Size;
   type Kth_Result is record
      Kth    : Value;         --  the K-th smallest entry of the block
      Tries  : Try_Count;     --  counts of the entries <= a value
      Probes : Probe_Count;   --  comparisons of an entry with a value
   end record;

   --  The K-th smallest: fewer than K entries are below it and at least
   --  K are <= it.
   function Kth (S : Sorted_Square; K : Rank) return Kth_Result
   with
     Global => null,
     Pre    => K <= S.N * S.N,
     Post   => Count (S, Kth'Result.Kth - 1) < K and then K <= Count (S, Kth'Result.Kth)
               and then Kth'Result.Probes <= 2 * S.N * Kth'Result.Tries;

private
   function Row_Count (M : Matrix; I : Dimension; X : Integer; J : Natural) return Natural is
     (if J = 0 then 0 else Row_Count (M, I, X, J - 1) + (if M (I, J) <= X then 1 else 0));

   function Total (M : Matrix; N : Dimension; X : Integer; I : Natural) return Natural is
     (if I = 0 then 0 else Total (M, N, X, I - 1) + Row_Count (M, I, X, N));
end Kth_Smallest_Matrix;
