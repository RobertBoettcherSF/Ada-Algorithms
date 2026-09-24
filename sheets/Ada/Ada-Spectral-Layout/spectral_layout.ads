package Spectral_Layout is

   -- Strong typing for algorithm-specific data
   type Node_Id is new Positive;
   
   -- Adjacency matrix represents the graph connections and weights
   type Adjacency_Matrix is array (Node_Id range <>, Node_Id range <>) of Float;
   
   -- 2D Coordinates for the layout
   type Coordinate is record
      X, Y : Float;
   end record;
   
   type Layout_Array is array (Node_Id range <>) of Coordinate;

   -- Exceptions for error handling
   Invalid_Graph_Format : exception; -- Raised if matrix is not square

   -- =======================================================================
   -- Variant 1: Unnormalized Laplacian (L = D - A)
   -- The classic spectral drawing using the 2nd and 3rd smallest eigenvectors.
   -- =======================================================================
   procedure Layout_Unnormalized_Laplacian (
      Graph  : in  Adjacency_Matrix;
      Layout : out Layout_Array
   );

   -- =======================================================================
   -- Variant 2: Normalized Laplacian (L_norm = D^(-1/2) L D^(-1/2))
   -- Modulates node placement by the degree of the node.
   -- =======================================================================
   procedure Layout_Normalized_Laplacian (
      Graph  : in  Adjacency_Matrix;
      Layout : out Layout_Array
   );

   -- =======================================================================
   -- Variant 3: Adjacency Matrix
   -- Layout based on the 1st and 2nd largest eigenvectors of A directly.
   -- =======================================================================
   procedure Layout_Adjacency (
      Graph  : in  Adjacency_Matrix;
      Layout : out Layout_Array
   );

end Spectral_Layout;
