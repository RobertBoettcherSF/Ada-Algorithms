--  Clustering_Algorithms — Ada 2023 educational survey package for
--  Wikipedia "Cluster analysis" (Data clustering redirects here):
--  partitioning objects into groups of greater intra-group similarity.
--  Survey covers connectivity, centroid, and density models plus
--  internal evaluation indices (WCSS, silhouette, Dunn).  Distribution
--  models (EM / GMM) are mentioned in README only.  Self-contained —
--  does NOT depend on sibling Ada-* packages; reimplements compact
--  representatives of Lloyd k-means, single-linkage, and DBSCAN.

pragma Ada_2022;

package Clustering_Algorithms
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   --  Digits 12 for stable distance / centroid / index arithmetic.
   type Real is digits 12;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Unit_Interval is Real range 0.0 .. 1.0;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   Max_Points : constant Positive := 64;
   Max_Dims   : constant Positive := 8;
   Max_K      : constant Positive := 16;

   subtype Point_Count is Natural  range 0 .. Max_Points;
   subtype Point_Index is Positive range 1 .. Max_Points;
   subtype Dim_Count   is Natural  range 0 .. Max_Dims;
   subtype Dim_Index   is Positive range 1 .. Max_Dims;
   subtype Site_Count  is Natural  range 0 .. Max_K;
   subtype Site_Index  is Positive range 1 .. Max_K;

   --  Coordinate vector of one observation / center.
   type Point is array (Dim_Index range <>) of Real;

   --  Data(P, D) = coordinate D of point P.  Rows = observations.
   type Dataset is array
     (Point_Index range <>, Dim_Index range <>) of Real;

   --  Centers(K, D) = coordinate D of centroid K.
   type Centers is array
     (Site_Index range <>, Dim_Index range <>) of Real;

   --  Cluster label per data point.  Positive = cluster id;
   --  Noise_Label (0) = noise / unset (DBSCAN convention).
   type Labels is array (Point_Index range <>) of Natural;

   Noise_Label : constant Natural := 0;

   --  Symmetric proximity matrix Dist(I, J).
   type Distance_Matrix is array
     (Point_Index range <>, Point_Index range <>) of Non_Negative;

   --  One agglomerative merge (single-linkage dendrogram).
   type Merge_Record is record
      Left   : Positive := 1;
      Right  : Positive := 1;
      Height : Non_Negative := 0.0;
      Size   : Positive := 1;
   end record;

   type Dendrogram is array (Positive range <>) of Merge_Record;

   type Empty_Flags is array (Site_Index range <>) of Boolean;

   type Index_List is array (Site_Index range <>) of Point_Index;

   type Init_Kind is (Forgy, Spaced);

   --  Lloyd / k-means run controls.
   type KMeans_Parameters is record
      K         : Site_Count := 2;
      Max_Iters : Positive := 100;
      Tol       : Non_Negative := 1.0E-6;
      Seed      : Natural := 1;
      Init      : Init_Kind := Spaced;
   end record;

   Default_KMeans : constant KMeans_Parameters := (others => <>);

   type KMeans_Result
     (N : Point_Count; K : Site_Count; D : Dim_Count)
   is record
      Centers   : Clustering_Algorithms.Centers (1 .. K, 1 .. D);
      Lab       : Labels (1 .. N);
      Empty     : Empty_Flags (1 .. K);
      WCSS      : Non_Negative := 0.0;
      Iters     : Natural := 0;
      Converged : Boolean := False;
   end record;

   --  DBSCAN parameters (ε, MinPts).
   type DBSCAN_Parameters is record
      Eps    : Positive_Real := 0.5;
      MinPts : Positive      := 3;
   end record;

   Default_DBSCAN : constant DBSCAN_Parameters := (others => <>);

   type DBSCAN_Result
     (First : Point_Index;
      Last  : Natural)
   is record
      Lab           : Labels (First .. Last);
      Cluster_Count : Natural := 0;
      Noise_Count   : Natural := 0;
   end record;

   type Point_Id_Array is array (Point_Index range <>) of Point_Index;

   --  Simple LCG PRNG (Numerical Recipes constants).
   type RNG_State is mod 2**32;

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

   procedure Seed_RNG (State : out RNG_State; Seed : Natural)
     with Global => null;

   function Draw_Unit (State : in out RNG_State) return Unit_Interval
     with Global => null;

   function Draw_Index
     (State : in out RNG_State; Lo, Hi : Point_Index) return Point_Index
     with Pre => Lo <= Hi, Global => null;

   ---------------------------------------------------------------------------
   -- Geometry (shared)
   ---------------------------------------------------------------------------

   function Distance (A, B : Point) return Non_Negative
     with Pre => A'First = B'First
       and then A'Last = B'Last
       and then A'Length >= 1
       and then A'Length <= Max_Dims,
          Global => null,
          Post => Distance'Result >= 0.0;
   --  Euclidean L2 ||A − B||.

   function Squared_Distance (A, B : Point) return Non_Negative
     with Pre => A'First = B'First
       and then A'Last = B'Last
       and then A'Length >= 1
       and then A'Length <= Max_Dims,
          Global => null,
          Post => Squared_Distance'Result >= 0.0;
   --  ||A − B||² (preferred for nearest-center comparisons).

   function Distance
     (Data : Dataset; P, Q : Point_Index) return Non_Negative
     with Pre => P in Data'Range (1) and then Q in Data'Range (1),
          Global => null;
   --  Euclidean L2 between dataset rows P and Q.

   function Extract_Point
     (Data : Dataset; P : Point_Index) return Point
     with Pre => P in Data'Range (1)
       and then Data'Length (2) >= 1
       and then Data'Length (2) <= Max_Dims,
          Global => null,
          Post => Extract_Point'Result'Length = Data'Length (2);

   function Extract_Center
     (C : Centers; K : Site_Index) return Point
     with Pre => K in C'Range (1)
       and then C'Length (2) >= 1
       and then C'Length (2) <= Max_Dims,
          Global => null,
          Post => Extract_Center'Result'Length = C'Length (2);

   ---------------------------------------------------------------------------
   -- Centroid model — Lloyd k-means
   ---------------------------------------------------------------------------

   function Nearest_Center
     (Query : Point; C : Centers) return Site_Index
     with Pre => Query'Length = C'Length (2)
       and then Query'Length >= 1
       and then C'Length (1) >= 1
       and then C'Length (1) <= Max_K,
          Global => null,
          Post => Nearest_Center'Result in C'Range (1);

   function Assign_Labels
     (Data : Dataset; C : Centers) return Labels
     with Pre => Data'Length (1) >= 1
       and then Data'Length (2) >= 1
       and then C'Length (1) >= 1
       and then C'Length (2) = Data'Length (2),
          Global => null,
          Post => Assign_Labels'Result'Length = Data'Length (1);
   --  Voronoi assignment: each point → nearest center (1 .. K).

   procedure Update_Centroids
     (Data  : Dataset;
      Lab   : Labels;
      C     : in out Centers;
      Empty : out Empty_Flags)
     with Pre => Data'Length (1) >= 1
       and then Lab'Length = Data'Length (1)
       and then Lab'First = Data'First (1)
       and then C'Length (1) >= 1
       and then C'Length (2) = Data'Length (2)
       and then Empty'Length = C'Length (1)
       and then Empty'First = C'First (1),
          Global => null;
   --  Move each center to the mean of its assigned points.
   --  Empty cluster → keep previous center, Empty(k) := True.

   function Init_Centers_Forgy
     (Data : Dataset;
      K    : Site_Count;
      Seed : Natural) return Centers
     with Pre => Data'Length (1) >= 1
       and then Data'Length (2) >= 1
       and then K >= 1
       and then K <= Data'Length (1),
          Global => null;

   function Init_Centers_Spaced
     (Data : Dataset; K : Site_Count) return Centers
     with Pre => Data'Length (1) >= 1
       and then Data'Length (2) >= 1
       and then K >= 1
       and then K <= Data'Length (1),
          Global => null;
   --  Deterministic spaced indices into the dataset.

   function Init_Centers_From_Indices
     (Data : Dataset; Idx : Index_List) return Centers
     with Pre => Data'Length (1) >= 1
       and then Idx'Length >= 1
       and then Data'Length (2) >= 1,
          Global => null;

   function Run_KMeans
     (Data   : Dataset;
      Init   : Centers;
      Params : KMeans_Parameters := Default_KMeans) return KMeans_Result
     with Pre => Data'Length (1) >= 1
       and then Data'Length (2) >= 1
       and then Init'Length (1) >= 1
       and then Init'Length (2) = Data'Length (2)
       and then Params.K = Init'Length (1)
       and then Params.Tol >= 0.0,
          Global => null;
   --  Lloyd iteration from given Init: assign → update until Tol / stable
   --  labels / Max_Iters.

   function Run_KMeans
     (Data   : Dataset;
      Params : KMeans_Parameters) return KMeans_Result
     with Pre => Data'Length (1) >= 1
       and then Data'Length (2) >= 1
       and then Params.K >= 1
       and then Params.K <= Data'Length (1)
       and then Params.Tol >= 0.0,
          Global => null;
   --  One-shot: Forgy or Spaced init (Params.Init) then Lloyd.

   ---------------------------------------------------------------------------
   -- Connectivity model — single-linkage agglomerative
   ---------------------------------------------------------------------------

   function Build_Distance_Matrix (Data : Dataset) return Distance_Matrix
     with Pre => Data'Length (1) >= 1
       and then Data'Length (1) <= Max_Points
       and then Data'Length (2) >= 1
       and then Data'Length (2) <= Max_Dims,
          Global => null;
   --  Pairwise Euclidean distances.

   function Run_Single_Linkage (Dist : Distance_Matrix) return Dendrogram
     with Pre => Dist'Length (1) >= 2
       and then Dist'Length (1) <= Max_Points
       and then Dist'Length (1) = Dist'Length (2),
          Global => null,
          Post => Run_Single_Linkage'Result'Length = Dist'Length (1) - 1;
   --  Naive O(n³) single-linkage (min-link) agglomeration.

   function Run_Single_Linkage (Data : Dataset) return Dendrogram
     with Pre => Data'Length (1) >= 2
       and then Data'Length (1) <= Max_Points
       and then Data'Length (2) >= 1,
          Global => null,
          Post => Run_Single_Linkage'Result'Length = Data'Length (1) - 1;

   function Labels_At_Height
     (Tree   : Dendrogram;
      N      : Point_Count;
      Height : Non_Negative) return Labels
     with Pre => N >= 2
       and then N <= Max_Points
       and then Tree'Length = N - 1,
          Global => null,
          Post => Labels_At_Height'Result'Length = N;
   --  Apply merges with Height <= cut; compact labels to 1 .. K.

   function Run_Single_Linkage_Cut
     (Data   : Dataset;
      Height : Non_Negative) return Labels
     with Pre => Data'Length (1) >= 2
       and then Data'Length (1) <= Max_Points
       and then Data'Length (2) >= 1,
          Global => null,
          Post => Run_Single_Linkage_Cut'Result'Length = Data'Length (1);
   --  Build dendrogram then cut at Height → flat labels.

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
   --  Apply first N−K merges → exactly K clusters.

   ---------------------------------------------------------------------------
   -- Density model — DBSCAN (compact)
   ---------------------------------------------------------------------------

   function Range_Query
     (Data : Dataset;
      P    : Point_Index;
      Eps  : Positive_Real) return Point_Id_Array
     with Pre => P in Data'Range (1),
          Global => null;
   --  N_ε(P): all Q with dist(P,Q) ≤ Eps, including P.

   function Neighbor_Count
     (Data : Dataset;
      P    : Point_Index;
      Eps  : Positive_Real) return Natural
     with Pre => P in Data'Range (1),
          Global => null;

   function Run_DBSCAN
     (Data   : Dataset;
      Params : DBSCAN_Parameters) return DBSCAN_Result
     with Pre => Data'Length (1) >= 1 and then Data'Length (2) >= 1,
          Global => null;
   --  Ester et al. query-based DBSCAN; Noise_Label for noise points.

   function Cluster_Count_Of (Lab : Labels) return Natural
     with Global => null;

   function Noise_Count_Of (Lab : Labels) return Natural
     with Global => null;

   ---------------------------------------------------------------------------
   -- Internal evaluation (Wikipedia Evaluation section)
   ---------------------------------------------------------------------------

   function Within_Cluster_SSE
     (Data : Dataset; C : Centers; Lab : Labels) return Non_Negative
     with Pre => Data'Length (1) >= 1
       and then Lab'Length = Data'Length (1)
       and then C'Length (1) >= 1
       and then C'Length (2) = Data'Length (2),
          Global => null,
          Post => Within_Cluster_SSE'Result >= 0.0;
   --  WCSS / SSE / inertia = Σ_i ||x_i − μ_{lab(i)}||².

   function WCSS
     (Data : Dataset; C : Centers; Lab : Labels) return Non_Negative
     renames Within_Cluster_SSE;

   function Mean_Silhouette
     (Data : Dataset; Lab : Labels) return Real
     with Pre => Data'Length (1) >= 2
       and then Lab'Length = Data'Length (1)
       and then Lab'First = Data'First (1)
       and then Data'Length (2) >= 1,
          Global => null;
   --  Mean silhouette coefficient over non-noise points.
   --  a = mean intra-cluster distance; b = mean dist to nearest other
   --  cluster; s = (b−a)/max(a,b).  Singleton clusters contribute 0.
   --  Raises Invalid_Argument if fewer than two non-noise labeled points
   --  or only one distinct positive cluster.

   function Dunn_Index
     (Data : Dataset; Lab : Labels) return Non_Negative
     with Pre => Data'Length (1) >= 2
       and then Lab'Length = Data'Length (1)
       and then Lab'First = Data'First (1)
       and then Data'Length (2) >= 1,
          Global => null,
          Post => Dunn_Index'Result >= 0.0;
   --  min inter-cluster distance / max intra-cluster distance.
   --  Noise points ignored.  Raises Invalid_Argument if < 2 clusters
   --  or a cluster has no finite diameter (handled as 0 denom → raise).

end Clustering_Algorithms;
