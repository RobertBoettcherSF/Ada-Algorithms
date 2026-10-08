--  Average_Linkage_Clustering — Ada 2023 educational package for Wikipedia
--  UPGMA (unweighted pair group method with arithmetic mean; Sokal & Michener):
--  agglomerative hierarchical clustering where cluster distance is the mean of
--  all pairwise distances between members.  "Unweighted" means each original
--  observation contributes equally (size-weighted / proportional averaging of
--  cluster distances).  Related siblings: Ada-Single-Linkage-Clustering,
--  Ada-Complete-Linkage-Clustering, Ada-Wards-Method.

pragma Ada_2022;

package Average_Linkage_Clustering
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   --  Digits 12 for stable distance / height arithmetic.
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

   --  Symmetric proximity / distance matrix Dist(I,J) for points I,J.
   --  Diagonal should be 0; off-diagonal entries non-negative.
   type Distance_Matrix is array
     (Point_Index range <>, Point_Index range <>) of Non_Negative;

   --  One agglomerative merge: clusters Left and Right joined at Height =
   --  average-linkage (UPGMA) distance.  Cluster IDs: leaves 1 .. N; the m-th
   --  merge creates cluster N + m  (m = 1 .. N−1).  Size = |Left| + |Right|.
   type Merge_Record is record
      Left   : Positive := 1;
      Right  : Positive := 1;
      Height : Non_Negative := 0.0;
      Size   : Positive := 1;
   end record;

   --  Full dendrogram: exactly N−1 merges for N points (index 1 .. N−1).
   type Dendrogram is array (Positive range <>) of Merge_Record;

   --  Alias for dendrogram + point count (hierarchy result).
   --  Last_Merge = N−1; discriminant alone constrains Tree'Last.
   type Hierarchy_Result (Last_Merge : Natural) is record
      N    : Point_Count := 0;
      Tree : Dendrogram (1 .. Last_Merge);
   end record;

   --  Cluster labels for points (typically 1 .. K after a cut).
   type Labels is array (Point_Index range <>) of Natural;

   --  Optional run parameters (Cut_Height used by Labels_At_Height helpers).
   type Parameters is record
      Cut_Height : Non_Negative := 0.0;
   end record;

   Default_Parameters : constant Parameters := (others => <>);

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument  : exception;
   Capacity_Exceeded : exception;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-8;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   ---------------------------------------------------------------------------
   -- Distances
   ---------------------------------------------------------------------------

   function Euclidean_Distance (A, B : Point) return Non_Negative
     with Pre => A'First = B'First
       and then A'Last = B'Last
       and then A'Length >= 1
       and then A'Length <= Max_Dims,
          Global => null,
          Post => Euclidean_Distance'Result >= 0.0;
   --  ||A − B||₂ (L2).  Raises Invalid_Argument if lengths differ or empty.

   function Build_Distance_Matrix (Data : Dataset) return Distance_Matrix
     with Pre => Data'Length (1) >= 1
       and then Data'Length (1) <= Max_Points
       and then Data'Length (2) >= 1
       and then Data'Length (2) <= Max_Dims,
          Global => null,
          Post => Build_Distance_Matrix'Result'Length (1) = Data'Length (1)
            and then Build_Distance_Matrix'Result'Length (2) =
              Data'Length (1);
   --  Pairwise Euclidean distances.  Raises Invalid_Argument if empty;
   --  Capacity_Exceeded if N > Max_Points or dims > Max_Dims.

   function Average_Linkage_Distance
     (Dist : Distance_Matrix;
      XA   : Labels;
      XB   : Labels) return Non_Negative
     with Pre => Dist'Length (1) = Dist'Length (2)
       and then Dist'Length (1) >= 1
       and then Dist'Length (1) <= Max_Points
       and then XA'Length >= 1
       and then XB'Length >= 1,
          Global => null,
          Post => Average_Linkage_Distance'Result >= 0.0;
   --  D(A,B) = (1/(|A||B|)) Σ_{x∈A} Σ_{y∈B} Dist(x,y).  Labels entries are
   --  1-based point indices into Dist.  Raises Invalid_Argument if an
   --  index is out of range or a set is empty.

   function UPGMA_Distance
     (Dist : Distance_Matrix;
      XA   : Labels;
      XB   : Labels) return Non_Negative
     renames Average_Linkage_Distance;
   --  Alias for Average_Linkage_Distance (mean pairwise / UPGMA linkage).

   function Cluster_Distance
     (Dist : Distance_Matrix;
      XA   : Labels;
      XB   : Labels) return Non_Negative
     renames Average_Linkage_Distance;
   --  Alias for Average_Linkage_Distance.

   ---------------------------------------------------------------------------
   -- Agglomerative clustering (UPGMA)
   ---------------------------------------------------------------------------

   function Run_Average_Linkage (Dist : Distance_Matrix) return Dendrogram
     with Pre => Dist'Length (1) >= 2
       and then Dist'Length (1) <= Max_Points
       and then Dist'Length (1) = Dist'Length (2),
          Global => null,
          Post => Run_Average_Linkage'Result'Length = Dist'Length (1) - 1;
   --  Naive O(n³) UPGMA agglomeration from a proximity matrix.
   --  Returns N−1 merges; Height is the average-linkage distance at that step.
   --  After merging A∪B, update d(A∪B,X) = (|A|·d(A,X)+|B|·d(B,X))/(|A|+|B|).
   --  Tie-break: lowest Left slot index, then lowest Right.
   --  Raises Invalid_Argument if N < 2 or matrix not square;
   --  Capacity_Exceeded if N > Max_Points.

   function Run_Average_Linkage (Data : Dataset) return Dendrogram
     with Pre => Data'Length (1) >= 2
       and then Data'Length (1) <= Max_Points
       and then Data'Length (2) >= 1
       and then Data'Length (2) <= Max_Dims,
          Global => null,
          Post => Run_Average_Linkage'Result'Length = Data'Length (1) - 1;
   --  Build Euclidean proximity matrix then Run_Average_Linkage (Dist).

   function Run_UPGMA (Dist : Distance_Matrix) return Dendrogram
     renames Run_Average_Linkage;
   --  Alias for Run_Average_Linkage (matrix).

   function Run_UPGMA (Data : Dataset) return Dendrogram
     renames Run_Average_Linkage;
   --  Alias for Run_Average_Linkage (points).

   function Merge_Height (Tree : Dendrogram; Step : Positive) return Non_Negative
     with Pre => Step in Tree'Range,
          Global => null,
          Post => Merge_Height'Result >= 0.0;
   --  Height (linkage distance) of merge Step.  Raises Invalid_Argument
   --  if Step out of Tree'Range.

   ---------------------------------------------------------------------------
   -- Cutting the dendrogram (flat clustering)
   ---------------------------------------------------------------------------

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
   --  Labels compacted to 1 .. K.  Raises Invalid_Argument if inconsistent.

   function Labels_At_Height
     (Tree   : Dendrogram;
      N      : Point_Count;
      Height : Non_Negative) return Labels
     with Pre => N >= 2
       and then N <= Max_Points
       and then Tree'Length = N - 1,
          Global => null,
          Post => Labels_At_Height'Result'Length = N;
   --  Apply every merge with merge.Height <= Height.
   --  Labels compacted to 1 .. K for whatever K results.
   --  Raises Invalid_Argument if Tree length ≠ N−1.

   function Labels_At_Height
     (Tree : Dendrogram;
      N    : Point_Count;
      P    : Parameters) return Labels
     with Pre => N >= 2
       and then N <= Max_Points
       and then Tree'Length = N - 1,
          Global => null,
          Post => Labels_At_Height'Result'Length = N;
   --  Same as Labels_At_Height (Tree, N, P.Cut_Height).

end Average_Linkage_Clustering;
