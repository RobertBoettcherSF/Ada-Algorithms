-- symbolic_cholesky.ads
-- Specification for the Symbolic Cholesky Decomposition.
-- Implements variants for identifying structural non-zeros (fill-in) 
-- prior to numerical Cholesky factorization.

package Symbolic_Cholesky is

   -- A boolean matrix type to represent the sparsity pattern (adjacency matrix of the graph)
   type Matrix is array (Positive range <>, Positive range <>) of Boolean;
   
   -- Array representing the Elimination Tree dependencies. 
   -- Tree_Array(I) = J means node J is the parent of node I. 
   -- A value of 0 means the node is a root (no parent).
   type Tree_Array is array (Positive range <>) of Natural;

   Invalid_Matrix : exception;

   -- VARIANT 1: Elimination Game (Parter-Rose Algorithm)
   -- Simulates Gaussian elimination on the graph without computing numerical values.
   -- A must be a square, symmetric matrix representing the initial non-zero pattern.
   -- Returns L, the lower-triangular pattern (including the diagonal) containing
   -- the original edges plus the "fill-in" edges created during elimination.
   function Elimination_Game (A : Matrix) return Matrix;

   -- VARIANT 2: Elimination Tree Computation
   -- The elimination tree is an optimal structure used in modern sparse matrix solvers 
   -- to define column dependencies. Parent of J is the smallest I > J where L(I, J) is non-zero.
   -- Requires the lower-triangular factor pattern L (e.g., from Elimination_Game).
   function Compute_Elimination_Tree (L : Matrix) return Tree_Array;

end Symbolic_Cholesky;
