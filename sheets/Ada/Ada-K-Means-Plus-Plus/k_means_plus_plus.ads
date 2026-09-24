--  K_Means_Plus_Plus — Ada 2023 educational package for Wikipedia
--  "k-means++" seeding (David Arthur & Sergei Vassilvitskii, 2007) followed
--  by standard Lloyd / batch k-means refinement.  D²-sampling initialization
--  yields an O(log k)-competitive guarantee in expectation versus the
--  optimal k-means objective.  Euclidean L2.  Self-contained (local Lloyd).

pragma Ada_2022;

package K_Means_Plus_Plus
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

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

   type Point is array (Dim_Index range <>) of Real;

   type Dataset is array
     (Point_Index range <>, Dim_Index range <>) of Real;

   --  Centers / Sites: row k is centroid k.
   type Centers is array
     (Site_Index range <>, Dim_Index range <>) of Real;

   subtype Sites is Centers;

   type Labels is array (Point_Index range <>) of Natural;

   type Empty_Flags is array (Site_Index range <>) of Boolean;

   --  Per-point squared distance to nearest already-chosen center (D(x)²).
   type D2_Weights is array (Point_Index range <>) of Non_Negative;

   --  Stream of Uniform_[0,1) draws for reproducible / injected RNG.
   type Uniform_Draws is array (Positive range <>) of Unit_Interval;

   type Parameters is record
      K         : Site_Count := 2;
      Max_Iters : Positive := 100;
      Tol       : Non_Negative := 1.0E-6;
      Seed      : Natural := 1;
   end record;

   Default_Parameters : constant Parameters := (others => <>);

   type Result
     (N : Point_Count; K : Site_Count; D : Dim_Count)
   is record
      Centroids : Centers (1 .. K, 1 .. D);
      Lab       : Labels (1 .. N);
      Empty     : Empty_Flags (1 .. K);
      Inertia   : Non_Negative := 0.0;
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

   function Squared_Distance (A, B : Point) return Non_Negative
     with Pre => A'First = B'First
       and then A'Last = B'Last
       and then A'Length >= 1
       and then A'Length <= Max_Dims,
          Global => null,
          Post => Squared_Distance'Result >= 0.0;

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

   function Extract_Site
     (S : Sites; K : Site_Index) return Point
     renames Extract_Center;

   ---------------------------------------------------------------------------
   -- Nearest center / D(x)²
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
   --  Argmin_k ||Query − C_k||² (ties → lowest index).

   function Min_Squared_Distance_To_Centers
     (Query : Point; C : Centers) return Non_Negative
     with Pre => Query'Length = C'Length (2)
       and then Query'Length >= 1
       and then C'Length (1) >= 1,
          Global => null,
          Post => Min_Squared_Distance_To_Centers'Result >= 0.0;
   --  D(x)² = min_k ||x − c_k||².

   function Compute_D2_Weights
     (Data : Dataset; C : Centers) return D2_Weights
     with Pre => Data'Length (1) >= 1
       and then Data'Length (2) = C'Length (2)
       and then C'Length (1) >= 1,
          Global => null,
          Post => Compute_D2_Weights'Result'Length = Data'Length (1);
   --  Per-point D(x)² for every row of Data.

   function Sum_D2 (W : D2_Weights) return Non_Negative
     with Global => null, Post => Sum_D2'Result >= 0.0;

   ---------------------------------------------------------------------------
   -- Assignment / centroids / quality
   ---------------------------------------------------------------------------

   function Assign_Labels
     (Data : Dataset; C : Centers) return Labels
     with Pre => Data'Length (1) >= 1
       and then Data'Length (2) = C'Length (2)
       and then C'Length (1) >= 1,
          Global => null,
          Post => Assign_Labels'Result'Length = Data'Length (1);

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
   --  Empty cluster: keep previous center and mark Empty(k).

   function Within_Cluster_SSE
     (Data : Dataset; C : Centers; Lab : Labels) return Non_Negative
     with Pre => Data'Length (1) >= 1
       and then Lab'Length = Data'Length (1)
       and then C'Length (1) >= 1
       and then C'Length (2) = Data'Length (2),
          Global => null,
          Post => Within_Cluster_SSE'Result >= 0.0;

   function Inertia
     (Data : Dataset; C : Centers; Lab : Labels) return Non_Negative
     renames Within_Cluster_SSE;

   ---------------------------------------------------------------------------
   -- Initialization (Arthur & Vassilvitskii 2007)
   ---------------------------------------------------------------------------

   function Init_Centers_Uniform_First
     (Data : Dataset; Seed : Natural) return Centers
     with Pre => Data'Length (1) >= 1
       and then Data'Length (1) <= Max_Points
       and then Data'Length (2) >= 1
       and then Data'Length (2) <= Max_Dims,
          Global => null,
          Post => Init_Centers_Uniform_First'Result'Length (1) = 1
            and then Init_Centers_Uniform_First'Result'Length (2) =
                       Data'Length (2);
   --  Choose one data row uniformly at random (LCG seeded by Seed).

   function Init_Centers_KMeansPP
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
          Post => Init_Centers_KMeansPP'Result'Length (1) = K
            and then Init_Centers_KMeansPP'Result'Length (2) =
                       Data'Length (2);
   --  Classic k-means++: first center uniform; subsequent centers sampled
   --  with probability ∝ D(x)².  Uses internal LCG from Seed.

   function Init_Centers_KMeansPP
     (Data  : Dataset;
      K     : Site_Count;
      Draws : Uniform_Draws) return Centers
     with Pre => Data'Length (1) >= 1
       and then Data'Length (1) <= Max_Points
       and then Data'Length (2) >= 1
       and then Data'Length (2) <= Max_Dims
       and then K >= 1
       and then K <= Max_K
       and then K <= Data'Length (1)
       and then Draws'Length >= K,
          Global => null,
          Post => Init_Centers_KMeansPP'Result'Length (1) = K
            and then Init_Centers_KMeansPP'Result'Length (2) =
                       Data'Length (2);
   --  Same algorithm driven by an explicit Uniform_[0,1) draw stream
   --  (Draws(1) → first center; Draws(2 .. K) → D² samples).  Deterministic
   --  when Draws are fixed.

   function Init_Centers_Farthest_Point
     (Data        : Dataset;
      K           : Site_Count;
      First_Index : Point_Index) return Centers
     with Pre => Data'Length (1) >= 1
       and then Data'Length (1) <= Max_Points
       and then Data'Length (2) >= 1
       and then Data'Length (2) <= Max_Dims
       and then K >= 1
       and then K <= Max_K
       and then K <= Data'Length (1)
       and then First_Index in Data'Range (1),
          Global => null,
          Post => Init_Centers_Farthest_Point'Result'Length (1) = K
            and then Init_Centers_Farthest_Point'Result'Length (2) =
                       Data'Length (2);
   --  Deterministic greedy D²-max seeding: first center = Data(First_Index);
   --  each next center = argmax_x D(x)² (ties → lowest index).  Useful as a
   --  test helper / farthest-point heuristic.

   function Init_Centers_From_Indices
     (Data : Dataset; Idx : Labels) return Centers
     with Pre => Data'Length (1) >= 1
       and then Idx'Length >= 1
       and then Idx'Length <= Max_K
       and then Data'Length (2) >= 1,
          Global => null,
          Post => Init_Centers_From_Indices'Result'Length (1) = Idx'Length
            and then Init_Centers_From_Indices'Result'Length (2) =
                       Data'Length (2);
   --  Copy Data rows given by Idx(1 .. K) as centers (for forced bad init).

   ---------------------------------------------------------------------------
   -- Lloyd refinement / full k-means++
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
   --  Standard Lloyd / batch k-means from given Init centers.

   function Run_KMeans
     (Data   : Dataset;
      Init   : Centers;
      Params : Parameters := Default_Parameters) return Result
     renames Run_Lloyd;

   function Run_KMeansPP
     (Data   : Dataset;
      Params : Parameters := Default_Parameters) return Result
     with Pre => Data'Length (1) >= 1
       and then Data'Length (1) <= Max_Points
       and then Data'Length (2) >= 1
       and then Data'Length (2) <= Max_Dims
       and then Params.K >= 1
       and then Params.K <= Max_K
       and then Params.K <= Data'Length (1)
       and then Params.Tol >= 0.0,
          Global => null;
   --  Init_Centers_KMeansPP (Params.Seed) then Run_Lloyd.

end K_Means_Plus_Plus;
