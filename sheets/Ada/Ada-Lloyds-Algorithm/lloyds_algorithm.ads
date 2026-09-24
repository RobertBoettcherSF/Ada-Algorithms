--  Lloyds_Algorithm — Ada 2023 educational package for Wikipedia
--  "Lloyd's algorithm" / Voronoi iteration / relaxation (Stuart P. Lloyd,
--  Bell Labs 1957, published 1982; independently Joel Max 1960 → Lloyd–Max).
--  Discrete form on a finite sample is the classic k-means iteration;
--  continuous form approximates a centroidal Voronoi tessellation (CVT).
--  Euclidean L2.  Empty clusters: keep previous site and mark empty.
--  Related (README only): Linde–Buzo–Gray vector quantization.

pragma Ada_2022;

package Lloyds_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   --  Digits 12 for stable centroid / inertia arithmetic.
   type Real is digits 12;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   Max_Points : constant Positive := 256;
   Max_Dims   : constant Positive := 16;
   Max_Sites  : constant Positive := 32;

   subtype Point_Count is Natural  range 0 .. Max_Points;
   subtype Point_Index is Positive range 1 .. Max_Points;
   subtype Dim_Count   is Natural  range 0 .. Max_Dims;
   subtype Dim_Index   is Positive range 1 .. Max_Dims;
   subtype Site_Count  is Natural  range 0 .. Max_Sites;
   subtype Site_Index  is Positive range 1 .. Max_Sites;

   --  Coordinate vector of one observation / site (length = dimensionality).
   type Point is array (Dim_Index range <>) of Real;

   --  Data(P, D) = coordinate D of point P.  Rows = observations.
   type Dataset is array
     (Point_Index range <>, Dim_Index range <>) of Real;

   --  Sites(K, D) = coordinate D of centroid / site K.
   type Sites is array
     (Site_Index range <>, Dim_Index range <>) of Real;

   --  Cluster label per data point (1 .. K); 0 = unset / unused.
   type Labels is array (Point_Index range <>) of Natural;

   --  Per-site emptiness after a centroid update (True = no assigned points).
   type Empty_Flags is array (Site_Index range <>) of Boolean;

   --  Run controls for discrete Lloyd / k-means.
   type Parameters is record
      K         : Site_Count := 2;
      Max_Iters : Positive := 100;
      Tol       : Non_Negative := 1.0E-6;
   end record;

   Default_Parameters : constant Parameters := (others => <>);

   --  Axis-aligned bounding box for 2-D grid CVT approximation.
   type BBox_2D is record
      X_Min, X_Max : Real := 0.0;
      Y_Min, Y_Max : Real := 1.0;
   end record;

   --  Full discrete fit outcome (discriminants fix storage extents).
   type Lloyd_Result
     (N : Point_Count; K : Site_Count; D : Dim_Count)
   is record
      Centroids  : Sites (1 .. K, 1 .. D);
      Lab        : Labels (1 .. N);
      Empty      : Empty_Flags (1 .. K);
      Inertia    : Non_Negative := 0.0;
      Iters      : Natural := 0;
      Converged  : Boolean := False;
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument  : exception;
   Capacity_Exceeded : exception;
   Degenerate_Cluster : exception;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-8;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   ---------------------------------------------------------------------------
   -- Geometry
   ---------------------------------------------------------------------------

   function Distance (A, B : Point) return Non_Negative
     with Pre => A'First = B'First
       and then A'Last = B'Last
       and then A'Length >= 1
       and then A'Length <= Max_Dims,
          Global => null,
          Post => Distance'Result >= 0.0;
   --  Euclidean L2 ||A − B||.  Raises Invalid_Argument if lengths differ.

   function Squared_Distance (A, B : Point) return Non_Negative
     with Pre => A'First = B'First
       and then A'Last = B'Last
       and then A'Length >= 1
       and then A'Length <= Max_Dims,
          Global => null,
          Post => Squared_Distance'Result >= 0.0;
   --  ||A − B||² (preferred for nearest-site comparisons).

   function Extract_Point
     (Data : Dataset; P : Point_Index) return Point
     with Pre => P in Data'Range (1)
       and then Data'Length (2) >= 1
       and then Data'Length (2) <= Max_Dims,
          Global => null,
          Post => Extract_Point'Result'Length = Data'Length (2);
   --  Row P as a Point (indices 1 .. Dims).

   function Extract_Site
     (S : Sites; K : Site_Index) return Point
     with Pre => K in S'Range (1)
       and then S'Length (2) >= 1
       and then S'Length (2) <= Max_Dims,
          Global => null,
          Post => Extract_Site'Result'Length = S'Length (2);
   --  Site row K as a Point (indices 1 .. Dims).

   ---------------------------------------------------------------------------
   -- Assignment / centroids / quality
   ---------------------------------------------------------------------------

   function Nearest_Site
     (Query : Point; S : Sites) return Site_Index
     with Pre => Query'Length = S'Length (2)
       and then Query'Length >= 1
       and then Query'Length <= Max_Dims
       and then S'Length (1) >= 1
       and then S'Length (1) <= Max_Sites,
          Global => null,
          Post => Nearest_Site'Result in S'Range (1);
   --  Argmin_k ||Query − S_k||² (ties → lowest site index).
   --  Raises Invalid_Argument if S empty or dims mismatch.

   function Assign_Labels
     (Data : Dataset; S : Sites) return Labels
     with Pre => Data'Length (1) >= 1
       and then Data'Length (1) <= Max_Points
       and then Data'Length (2) >= 1
       and then Data'Length (2) <= Max_Dims
       and then S'Length (1) >= 1
       and then S'Length (1) <= Max_Sites
       and then S'Length (2) = Data'Length (2),
          Global => null,
          Post => Assign_Labels'Result'Length = Data'Length (1);
   --  Voronoi partition of the sample: each point → nearest site (1 .. K).

   procedure Compute_Centroids
     (Data       : Dataset;
      Lab        : Labels;
      S          : in out Sites;
      Empty      : out Empty_Flags;
      Raise_Empty : Boolean := False)
     with Pre => Data'Length (1) >= 1
       and then Lab'Length = Data'Length (1)
       and then Lab'First = Data'First (1)
       and then S'Length (1) >= 1
       and then S'Length (2) = Data'Length (2)
       and then Empty'Length = S'Length (1)
       and then Empty'First = S'First (1),
          Global => null;
   --  Move each site to the mean of points labeled with that site.
   --  Empty cluster policy: keep previous site coordinates and set
   --  Empty(k) := True.  If Raise_Empty, also raise Degenerate_Cluster
   --  when any cluster is empty (after the keep update).

   function Within_Cluster_SSE
     (Data : Dataset; S : Sites; Lab : Labels) return Non_Negative
     with Pre => Data'Length (1) >= 1
       and then Lab'Length = Data'Length (1)
       and then S'Length (1) >= 1
       and then S'Length (2) = Data'Length (2),
          Global => null,
          Post => Within_Cluster_SSE'Result >= 0.0;
   --  Inertia / SSE = Σ_i ||x_i − μ_{lab(i)}||².

   function Inertia
     (Data : Dataset; S : Sites; Lab : Labels) return Non_Negative
     renames Within_Cluster_SSE;
   --  Alias for Within_Cluster_SSE (k-means terminology).

   ---------------------------------------------------------------------------
   -- Initialization
   ---------------------------------------------------------------------------

   function Init_Sites_From_Data
     (Data : Dataset; K : Site_Count) return Sites
     with Pre => Data'Length (1) >= 1
       and then Data'Length (1) <= Max_Points
       and then Data'Length (2) >= 1
       and then Data'Length (2) <= Max_Dims
       and then K >= 1
       and then K <= Max_Sites
       and then K <= Data'Length (1),
          Global => null,
          Post => Init_Sites_From_Data'Result'Length (1) = K
            and then Init_Sites_From_Data'Result'Length (2) =
                       Data'Length (2);
   --  Deterministic init: spaced indices
   --    i_j = 1 + floor((j−1)·(N−1)/(K−1)) for K>1, else {1}.
   --  Copies those data rows as initial sites.  Raises Invalid_Argument
   --  if K < 1 or K > N; Capacity_Exceeded if caps exceeded.

   ---------------------------------------------------------------------------
   -- Discrete Lloyd / k-means
   ---------------------------------------------------------------------------

   function Run_Lloyd
     (Data : Dataset;
      Init : Sites;
      Params : Parameters := Default_Parameters) return Lloyd_Result
     with Pre => Data'Length (1) >= 1
       and then Data'Length (1) <= Max_Points
       and then Data'Length (2) >= 1
       and then Data'Length (2) <= Max_Dims
       and then Init'Length (1) >= 1
       and then Init'Length (2) = Data'Length (2)
       and then Params.K = Init'Length (1)
       and then Params.K <= Max_Sites
       and then Params.Tol >= 0.0,
          Global => null;
   --  Discrete Lloyd iteration (k-means form):
   --    1. Assign each point to nearest site (Voronoi of the sample).
   --    2. Move each site to mean of assigned points (empty → keep + mark).
   --    3. Stop when max site displacement < Tol or Max_Iters reached.
   --  Converged = True iff displacement criterion met.
   --  Raises Invalid_Argument / Capacity_Exceeded on bad inputs.

   function Run_KMeans
     (Data : Dataset;
      Init : Sites;
      Params : Parameters := Default_Parameters) return Lloyd_Result
     renames Run_Lloyd;
   --  Alias: discrete Lloyd ≡ batch k-means (Lloyd / Forgy form).

   function Run_Lloyd
     (Data : Dataset;
      Params : Parameters) return Lloyd_Result
     with Pre => Data'Length (1) >= 1
       and then Data'Length (1) <= Max_Points
       and then Data'Length (2) >= 1
       and then Data'Length (2) <= Max_Dims
       and then Params.K >= 1
       and then Params.K <= Max_Sites
       and then Params.K <= Data'Length (1)
       and then Params.Tol >= 0.0,
          Global => null;
   --  Convenience: Init_Sites_From_Data then Run_Lloyd.

   ---------------------------------------------------------------------------
   -- Continuous CVT approximation (2-D uniform grid)
   ---------------------------------------------------------------------------

   function Run_Lloyd_Grid_2D
     (Box        : BBox_2D;
      Resolution : Positive;
      Init       : Sites;
      Max_Iters  : Positive := 50;
      Tol        : Non_Negative := 1.0E-6) return Sites
     with Pre => Init'Length (1) >= 1
       and then Init'Length (1) <= Max_Sites
       and then Init'Length (2) = 2
       and then Resolution >= 2
       and then Resolution <= 128
       and then Box.X_Max > Box.X_Min
       and then Box.Y_Max > Box.Y_Min
       and then Tol >= 0.0,
          Global => null,
          Post => Run_Lloyd_Grid_2D'Result'Length (1) = Init'Length (1)
            and then Run_Lloyd_Grid_2D'Result'Length (2) = 2;
   --  Grid approximation of continuous Lloyd / CVT in 2-D:
   --  uniform Resolution×Resolution samples over Box; assign each sample
   --  to nearest site; replace sites by sample-cell means; iterate.
   --  Empty cell: keep previous site.  Stops on max displacement < Tol
   --  or Max_Iters.  Raises Invalid_Argument on degenerate box / dims.

end Lloyds_Algorithm;
