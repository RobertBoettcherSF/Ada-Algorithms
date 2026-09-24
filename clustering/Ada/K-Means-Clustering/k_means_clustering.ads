--  K_Means_Clustering — Ada 2023 educational package for Wikipedia
--  "k-means clustering": vector quantization that partitions n observations
--  into k clusters minimizing within-cluster sum of squares (WCSS / inertia).
--  Standard / naïve algorithm is Lloyd's iteration (assign → mean update).
--  Euclidean L2 / squared L2.  Empty clusters: keep previous mean + mark.
--  Self-contained (no dependency on Ada-Lloyds-Algorithm or Ada-K-Means-Plus-Plus).

pragma Ada_2022;

package K_Means_Clustering
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   --  Digits 12 for stable centroid / WCSS arithmetic.
   type Real is digits 12;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Unit_Interval is Real range 0.0 .. 1.0;

   Max_Points : constant Positive := 256;
   Max_Dims   : constant Positive := 16;
   Max_K      : constant Positive := 32;

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

   --  Cluster label per data point (1 .. K); 0 = unset / unused.
   type Labels is array (Point_Index range <>) of Natural;

   --  Per-center emptiness after a centroid update (True = no assigned points).
   type Empty_Flags is array (Site_Index range <>) of Boolean;

   --  Indices into the dataset (for Init_Centers_From_Indices).
   type Index_List is array (Site_Index range <>) of Point_Index;

   --  Run controls for Lloyd / k-means.
   type Parameters is record
      K         : Site_Count := 2;
      Max_Iters : Positive := 100;
      Tol       : Non_Negative := 1.0E-6;
      Seed      : Natural := 1;
   end record;

   Default_Parameters : constant Parameters := (others => <>);

   --  Full fit outcome (discriminants fix storage extents).
   type Result
     (N : Point_Count; K : Site_Count; D : Dim_Count)
   is record
      Centers   : K_Means_Clustering.Centers (1 .. K, 1 .. D);
      Lab       : Labels (1 .. N);
      Empty     : Empty_Flags (1 .. K);
      WCSS      : Non_Negative := 0.0;
      Inertia   : Non_Negative := 0.0;  -- alias of WCSS (filled identically)
      Iters     : Natural := 0;
      Converged : Boolean := False;
   end record;

   ---------------------------------------------------------------------------
   -- Simple LCG PRNG (Numerical Recipes constants; 32-bit modular)
   ---------------------------------------------------------------------------

   type RNG_State is mod 2**32;

   procedure Seed_RNG (State : out RNG_State; Seed : Natural)
     with Global => null;
   --  Maps Seed into a non-zero 32-bit state.

   function Draw_Unit (State : in out RNG_State) return Unit_Interval
     with Global => null;
   --  Next Uniform_[0,1) draw; advances State.

   function Draw_Index
     (State : in out RNG_State; Lo, Hi : Point_Index) return Point_Index
     with Pre => Lo <= Hi, Global => null;
   --  Uniform integer in Lo .. Hi inclusive.

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
   --  ||A − B||² (preferred for nearest-center comparisons).

   function Extract_Point
     (Data : Dataset; P : Point_Index) return Point
     with Pre => P in Data'Range (1)
       and then Data'Length (2) >= 1
       and then Data'Length (2) <= Max_Dims,
          Global => null,
          Post => Extract_Point'Result'Length = Data'Length (2);
   --  Row P as a Point (indices 1 .. Dims).

   function Extract_Center
     (C : Centers; K : Site_Index) return Point
     with Pre => K in C'Range (1)
       and then C'Length (2) >= 1
       and then C'Length (2) <= Max_Dims,
          Global => null,
          Post => Extract_Center'Result'Length = C'Length (2);
   --  Center row K as a Point (indices 1 .. Dims).

   ---------------------------------------------------------------------------
   -- Assignment / centroids / quality
   ---------------------------------------------------------------------------

   function Nearest_Center
     (Query : Point; C : Centers) return Site_Index
     with Pre => Query'Length = C'Length (2)
       and then Query'Length >= 1
       and then Query'Length <= Max_Dims
       and then C'Length (1) >= 1
       and then C'Length (1) <= Max_K,
          Global => null,
          Post => Nearest_Center'Result in C'Range (1);
   --  Argmin_k ||Query − C_k||² (ties → lowest center index).
   --  Raises Invalid_Argument if C empty or dims mismatch.

   function Assign_Labels
     (Data : Dataset; C : Centers) return Labels
     with Pre => Data'Length (1) >= 1
       and then Data'Length (1) <= Max_Points
       and then Data'Length (2) >= 1
       and then Data'Length (2) <= Max_Dims
       and then C'Length (1) >= 1
       and then C'Length (1) <= Max_K
       and then C'Length (2) = Data'Length (2),
          Global => null,
          Post => Assign_Labels'Result'Length = Data'Length (1);
   --  Voronoi partition of the sample: each point → nearest center (1 .. K).

   procedure Compute_Centroids
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
   --  Move each center to the mean of points labeled with that center.
   --  Empty cluster policy: keep previous center coordinates and set
   --  Empty(k) := True.

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
   --  Alias for Within_Cluster_SSE (Wikipedia terminology).

   function Inertia
     (Data : Dataset; C : Centers; Lab : Labels) return Non_Negative
     renames Within_Cluster_SSE;
   --  Alias for Within_Cluster_SSE (scikit-learn / ML terminology).

   ---------------------------------------------------------------------------
   -- Initialization
   ---------------------------------------------------------------------------

   function Init_Centers_Forgy
     (Data : Dataset;
      K    : Site_Count;
      Seed : Natural) return Centers
     with Pre => Data'Length (1) >= 1
       and then Data'Length (1) <= Max_Points
       and then Data'Length (2) >= 1
       and then Data'Length (2) <= Max_Dims
       and then K >= 1
       and then K <= Max_K
       and then K <= Data'Length (1),
          Global => null,
          Post => Init_Centers_Forgy'Result'Length (1) = K
            and then Init_Centers_Forgy'Result'Length (2) =
                       Data'Length (2);
   --  Forgy init: choose K distinct data rows uniformly at random as
   --  initial centers, using a seeded LCG.  Raises Invalid_Argument if
   --  K < 1 or K > N; Capacity_Exceeded if caps exceeded.

   function Init_Centers_From_Indices
     (Data : Dataset; Idx : Index_List) return Centers
     with Pre => Data'Length (1) >= 1
       and then Idx'Length >= 1
       and then Idx'Length <= Max_K
       and then Data'Length (2) >= 1,
          Global => null,
          Post => Init_Centers_From_Indices'Result'Length (1) = Idx'Length
            and then Init_Centers_From_Indices'Result'Length (2) =
                       Data'Length (2);
   --  Copy Data rows given by Idx as centers (user-supplied indices).

   function Init_Centers_Spaced
     (Data : Dataset; K : Site_Count) return Centers
     with Pre => Data'Length (1) >= 1
       and then Data'Length (1) <= Max_Points
       and then Data'Length (2) >= 1
       and then Data'Length (2) <= Max_Dims
       and then K >= 1
       and then K <= Max_K
       and then K <= Data'Length (1),
          Global => null,
          Post => Init_Centers_Spaced'Result'Length (1) = K
            and then Init_Centers_Spaced'Result'Length (2) =
                       Data'Length (2);
   --  Deterministic spaced indices:
   --    i_j = 1 + floor((j−1)·(N−1)/(K−1)) for K>1, else {1}.
   --  Copies those data rows as initial centers.

   ---------------------------------------------------------------------------
   -- Lloyd / naïve k-means
   ---------------------------------------------------------------------------

   function Run_Lloyd
     (Data   : Dataset;
      Init   : Centers;
      Params : Parameters := Default_Parameters) return Result
     with Pre => Data'Length (1) >= 1
       and then Data'Length (1) <= Max_Points
       and then Data'Length (2) >= 1
       and then Data'Length (2) <= Max_Dims
       and then Init'Length (1) >= 1
       and then Init'Length (2) = Data'Length (2)
       and then Params.K = Init'Length (1)
       and then Params.K <= Max_K
       and then Params.Tol >= 0.0,
          Global => null;
   --  Standard Lloyd / naïve k-means from given Init centers:
   --    1. Assign each point to nearest center (squared Euclidean).
   --    2. Move each center to mean of assigned points (empty → keep + mark).
   --    3. Stop when max center displacement < Tol, assignments stable,
   --       or Max_Iters reached.
   --  Converged = True iff displacement or assignment-stability criterion met.

   function Run_KMeans
     (Data   : Dataset;
      Init   : Centers;
      Params : Parameters := Default_Parameters) return Result
     renames Run_Lloyd;
   --  Alias: naïve k-means ≡ discrete Lloyd (batch / Forgy form).

   function Run_KMeans
     (Data   : Dataset;
      Params : Parameters) return Result
     with Pre => Data'Length (1) >= 1
       and then Data'Length (1) <= Max_Points
       and then Data'Length (2) >= 1
       and then Data'Length (2) <= Max_Dims
       and then Params.K >= 1
       and then Params.K <= Max_K
       and then Params.K <= Data'Length (1)
       and then Params.Tol >= 0.0,
          Global => null;
   --  One-shot: Init_Centers_Forgy (Params.Seed) then Run_Lloyd.

   function Run_Lloyd
     (Data   : Dataset;
      Params : Parameters) return Result
     renames Run_KMeans;
   --  Alias of one-shot Forgy + Lloyd.

end K_Means_Clustering;
