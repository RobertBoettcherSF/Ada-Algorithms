--  Wards_Method — Ada 2023 educational package for Wikipedia
--  "Ward's method" / Ward's minimum variance hierarchical clustering
--  (Joe H. Ward, Jr., 1963): agglomerative clustering that merges the pair
--  of clusters minimizing the increase in total within-cluster error sum of
--  squares (ESS / SSE). Initial singleton distances are squared Euclidean;
--  distances are updated by the Lance–Williams recursion with Ward
--  coefficients (α_i, α_j, β, γ=0). Naive O(n³) implementation for small n.
--  Related (README notes only): single linkage, complete linkage, UPGMA.

pragma Ada_2022;

package Wards_Method
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   --  Digits 12 for stable distance / ESS arithmetic.
   type Real is digits 12;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   Max_Points : constant Positive := 64;
   Max_Dims   : constant Positive := 16;

   subtype Point_Count is Natural  range 0 .. Max_Points;
   subtype Point_Index is Positive range 1 .. Max_Points;
   subtype Dim_Count   is Natural  range 0 .. Max_Dims;
   subtype Dim_Index   is Positive range 1 .. Max_Dims;

   --  Coordinate vector of one observation (length = dimensionality).
   type Point is array (Dim_Index range <>) of Real;

   --  Data(P, D) = coordinate D of point P.  Rows = observations.
   type Dataset is array
     (Point_Index range <>, Dim_Index range <>) of Real;

   --  One agglomerative merge: clusters Left and Right joined at Height = Δ
   --  (increase in within-cluster SSE).  Cluster IDs: leaves 1 .. N;
   --  the m-th merge creates cluster N + m  (m = 1 .. N−1).
   type Merge_Record is record
      Left   : Positive := 1;
      Right  : Positive := 1;
      Height : Non_Negative := 0.0;
   end record;

   --  Full dendrogram: exactly N−1 merges for N points (index 1 .. N−1).
   type Dendrogram is array (Positive range <>) of Merge_Record;

   --  Cluster labels for points (typically 1 .. K after a cut).
   type Labels is array (Point_Index range <>) of Natural;

   --  Cluster sizes used by Lance–Williams / Ward_Delta.
   type Size_Array is array (Point_Index range <>) of Natural;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument    : exception;
   Degenerate_Geometry : exception;
   Capacity_Exceeded   : exception;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-8;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   ---------------------------------------------------------------------------
   -- Geometry / Ward criterion
   ---------------------------------------------------------------------------

   function Squared_Euclidean (A, B : Point) return Non_Negative
     with Pre => A'First = B'First
       and then A'Last = B'Last
       and then A'Length >= 1
       and then A'Length <= Max_Dims,
          Global => null,
          Post => Squared_Euclidean'Result >= 0.0;
   --  ||A − B||².  Raises Invalid_Argument if lengths differ or empty.

   function Centroid (Data : Dataset) return Point
     with Pre => Data'Length (1) >= 1
       and then Data'Length (1) <= Max_Points
       and then Data'Length (2) >= 1
       and then Data'Length (2) <= Max_Dims,
          Global => null;
   --  Coordinate-wise mean of all rows.  Raises Invalid_Argument if empty.

   function Ward_Delta
     (Ni, Nj          : Positive;
      Mu_I, Mu_J      : Point) return Non_Negative
     with Pre => Ni >= 1
       and then Nj >= 1
       and then Mu_I'First = Mu_J'First
       and then Mu_I'Last = Mu_J'Last
       and then Mu_I'Length >= 1
       and then Mu_I'Length <= Max_Dims,
          Global => null,
          Post => Ward_Delta'Result >= 0.0;
   --  Merge cost / ESS increase:
   --    Δ(i,j) = (n_i n_j)/(n_i+n_j) · ||μ_i − μ_j||².
   --  For two singletons this equals half the squared Euclidean distance.

   function Ward_Delta_From_Dist
     (Ni, Nj : Positive; Dist_Sq_Centroids : Non_Negative)
      return Non_Negative
     with Pre => Ni >= 1 and then Nj >= 1,
          Global => null,
          Post => Ward_Delta_From_Dist'Result >= 0.0;
   --  Same Δ given ||μ_i − μ_j||² directly.

   ---------------------------------------------------------------------------
   -- Lance–Williams recursion (Ward coefficients)
   ---------------------------------------------------------------------------

   function Lance_Williams_Ward
     (Ni, Nj, Nk : Positive;
      Dik, Djk, Dij : Real) return Real
     with Pre => Ni >= 1 and then Nj >= 1 and then Nk >= 1,
          Global => null;
   --  After merging i and j into (ij), distance to cluster k:
   --    α_i = (n_i+n_k)/(n_i+n_j+n_k),
   --    α_j = (n_j+n_k)/(n_i+n_j+n_k),
   --    β   = −n_k/(n_i+n_j+n_k),  γ = 0,
   --    d_{(ij)k} = α_i d_ik + α_j d_jk + β d_ij.
   --  With squared-Euclidean initialization, d equals 2·Δ.

   ---------------------------------------------------------------------------
   -- Agglomerative clustering
   ---------------------------------------------------------------------------

   function Ward_Linkage (Data : Dataset) return Dendrogram
     with Pre => Data'Length (1) >= 2
       and then Data'Length (1) <= Max_Points
       and then Data'Length (2) >= 1
       and then Data'Length (2) <= Max_Dims,
          Global => null,
          Post => Ward_Linkage'Result'Length = Data'Length (1) - 1;
   --  Naive O(n³) Ward agglomeration until one cluster.
   --  Returns N−1 merges; Height is the ESS increase Δ at that step.
   --  Tie-break: lowest Left index, then lowest Right index.
   --  Raises Invalid_Argument if N < 2 or dims empty;
   --  Capacity_Exceeded if N > Max_Points or dims > Max_Dims.

   function Cut_Dendrogram
     (Tree : Dendrogram;
      N    : Point_Count;
      K    : Positive) return Labels
     with Pre => N >= 2
       and then N <= Max_Points
       and then Tree'Length = N - 1
       and then K >= 1
       and then K <= N,
          Global => null,
          Post => Cut_Dendrogram'Result'Length = N;
   --  Cut the tree into K clusters (apply first N−K merges).
   --  Labels are compacted to 1 .. K.  Raises Invalid_Argument if K or N
   --  is inconsistent with Tree.

   function Within_Cluster_SSE
     (Data : Dataset; Lab : Labels) return Non_Negative
     with Pre => Data'Length (1) >= 1
       and then Data'Length (1) <= Max_Points
       and then Lab'Length = Data'Length (1)
       and then Data'Length (2) >= 1
       and then Data'Length (2) <= Max_Dims,
          Global => null,
          Post => Within_Cluster_SSE'Result >= 0.0;
   --  Total within-cluster sum of squared errors about each cluster mean.
   --  Raises Invalid_Argument if a label is zero / unused inconsistently
   --  enough to yield an empty referenced cluster with points claiming it.

end Wards_Method;
