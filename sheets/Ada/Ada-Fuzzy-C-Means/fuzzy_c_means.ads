--  Fuzzy_C_Means — Ada 2023 educational package for Wikipedia
--  "Fuzzy clustering" / Fuzzy c-means (FCM): soft clustering with
--  memberships w_ij ∈ [0,1], rows sum to 1.  Developed by J.C. Dunn
--  (1973), improved by J.C. Bezdek (1981).  Objective
--    J(W,C) = Σ_i Σ_j w_ij^m ||x_i − c_j||²
--  Euclidean L2.  As m→1 approaches hard k-means.  Self-contained
--  (no dependency on Ada-K-Means-Clustering).

pragma Ada_2022;

package Fuzzy_C_Means
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   --  Digits 12 for stable membership / centroid arithmetic.
   type Real is digits 12;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Unit_Interval is Real range 0.0 .. 1.0;
   --  Fuzzifier m must be > 1; common default m = 2.
   subtype Fuzzifier is Real range 1.0 .. Real'Last;

   Max_Points   : constant Positive := 256;
   Max_Dims     : constant Positive := 16;
   Max_Clusters : constant Positive := 32;

   subtype Point_Count   is Natural  range 0 .. Max_Points;
   subtype Point_Index   is Positive range 1 .. Max_Points;
   subtype Dim_Count     is Natural  range 0 .. Max_Dims;
   subtype Dim_Index     is Positive range 1 .. Max_Dims;
   subtype Cluster_Count is Natural  range 0 .. Max_Clusters;
   subtype Cluster_Index is Positive range 1 .. Max_Clusters;

   --  Coordinate vector of one observation / center.
   type Point is array (Dim_Index range <>) of Real;

   --  Data(P, D) = coordinate D of point P.  Rows = observations.
   type Dataset is array
     (Point_Index range <>, Dim_Index range <>) of Real;

   --  Centers(J, D) = coordinate D of cluster center J.
   type Centers is array
     (Cluster_Index range <>, Dim_Index range <>) of Real;

   --  Membership_Matrix(I, J) = w_ij ∈ [0,1]; each row sums to 1.
   type Membership_Matrix is array
     (Point_Index range <>, Cluster_Index range <>) of Real;

   --  Hard label per data point (1 .. C); 0 = unset / unused.
   type Hard_Labels is array (Point_Index range <>) of Natural;

   --  Run controls for FCM.
   type Parameters is record
      C           : Cluster_Count := 2;
      Fuzzifier_M : Fuzzifier := 2.0;
      Eps         : Non_Negative := 1.0E-5;
      Max_Iters   : Positive := 100;
      Seed        : Natural := 1;
   end record;

   Default_Parameters : constant Parameters := (others => <>);

   --  Full fit outcome (discriminants fix storage extents).
   type Result
     (N : Point_Count; C : Cluster_Count; D : Dim_Count)
   is record
      Centers     : Fuzzy_C_Means.Centers (1 .. C, 1 .. D);
      Memberships : Membership_Matrix (1 .. N, 1 .. C);
      Objective_J : Non_Negative := 0.0;
      Iters       : Natural := 0;
      Converged   : Boolean := False;
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

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument  : exception;
   Capacity_Exceeded : exception;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-8;
   --  Floor for squared distances in membership update (zero-distance guard).
   Distance_Eps : constant Real := 1.0E-30;

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
   --  Euclidean L2 ||A − B||.

   function Squared_Distance (A, B : Point) return Non_Negative
     with Pre => A'First = B'First
       and then A'Last = B'Last
       and then A'Length >= 1
       and then A'Length <= Max_Dims,
          Global => null,
          Post => Squared_Distance'Result >= 0.0;
   --  ||A − B||².

   function Extract_Point
     (Data : Dataset; P : Point_Index) return Point
     with Pre => P in Data'Range (1)
       and then Data'Length (2) >= 1
       and then Data'Length (2) <= Max_Dims,
          Global => null,
          Post => Extract_Point'Result'Length = Data'Length (2);

   function Extract_Center
     (C : Centers; J : Cluster_Index) return Point
     with Pre => J in C'Range (1)
       and then C'Length (2) >= 1
       and then C'Length (2) <= Max_Dims,
          Global => null,
          Post => Extract_Center'Result'Length = C'Length (2);

   ---------------------------------------------------------------------------
   -- Initialization
   ---------------------------------------------------------------------------

   function Init_Memberships_Random
     (N    : Point_Count;
      C    : Cluster_Count;
      Seed : Natural) return Membership_Matrix
     with Pre => N >= 1
       and then N <= Max_Points
       and then C >= 2
       and then C <= Max_Clusters,
          Global => null,
          Post => Init_Memberships_Random'Result'Length (1) = N
            and then Init_Memberships_Random'Result'Length (2) = C;
   --  Seeded LCG: draw positive weights per row, normalize so Σ_j w_ij = 1.
   --  Raises Invalid_Argument if C < 2 or N < 1; Capacity_Exceeded if caps.

   ---------------------------------------------------------------------------
   -- Update steps / objective
   ---------------------------------------------------------------------------

   procedure Update_Centers
     (Data : Dataset;
      W    : Membership_Matrix;
      M    : Fuzzifier;
      Ctr  : in out Centers)
     with Pre => Data'Length (1) >= 1
       and then W'Length (1) = Data'Length (1)
       and then W'First (1) = Data'First (1)
       and then Ctr'Length (1) >= 1
       and then Ctr'Length (2) = Data'Length (2)
       and then W'Length (2) = Ctr'Length (1)
       and then M > 1.0,
          Global => null;
   --  c_j = Σ_i w_ij^m x_i / Σ_i w_ij^m.
   --  If a cluster's weight sum is ~0, keep previous center.

   procedure Update_Memberships
     (Data : Dataset;
      Ctr  : Centers;
      M    : Fuzzifier;
      W    : in out Membership_Matrix)
     with Pre => Data'Length (1) >= 1
       and then W'Length (1) = Data'Length (1)
       and then W'First (1) = Data'First (1)
       and then Ctr'Length (1) >= 1
       and then Ctr'Length (2) = Data'Length (2)
       and then W'Length (2) = Ctr'Length (1)
       and then M > 1.0,
          Global => null;
   --  w_ij = 1 / Σ_k (||x_i−c_j|| / ||x_i−c_k||)^(2/(m−1)).
   --  Zero-distance: if x_i = c_j (within Distance_Eps on squared dist),
   --  set w_ij = 1 and other memberships 0 for that i.

   function Objective_J
     (Data : Dataset;
      Ctr  : Centers;
      W    : Membership_Matrix;
      M    : Fuzzifier) return Non_Negative
     with Pre => Data'Length (1) >= 1
       and then W'Length (1) = Data'Length (1)
       and then Ctr'Length (1) >= 1
       and then Ctr'Length (2) = Data'Length (2)
       and then W'Length (2) = Ctr'Length (1)
       and then M > 1.0,
          Global => null,
          Post => Objective_J'Result >= 0.0;
   --  J(W,C) = Σ_i Σ_j w_ij^m ||x_i − c_j||².

   ---------------------------------------------------------------------------
   -- Main algorithm
   ---------------------------------------------------------------------------

   function Run_Fuzzy_C_Means
     (Data   : Dataset;
      Params : Parameters := Default_Parameters) return Result
     with Pre => Data'Length (1) >= 1
       and then Data'Length (1) <= Max_Points
       and then Data'Length (2) >= 1
       and then Data'Length (2) <= Max_Dims
       and then Params.C >= 2
       and then Params.C <= Max_Clusters
       and then Params.C <= Data'Length (1)
       and then Params.Fuzzifier_M > 1.0
       and then Params.Eps >= 0.0,
          Global => null;
   --  1. Init memberships randomly (Params.Seed), rows sum to 1.
   --  2. Update centers from W.
   --  3. Update W from centers.
   --  4. Until max |Δw| < Eps or Max_Iters.
   --  Raises Invalid_Argument if m ≤ 1, C < 2, or C > N;
   --  Capacity_Exceeded if dims/points exceed caps.

   function Run_FCM
     (Data   : Dataset;
      Params : Parameters := Default_Parameters) return Result
     renames Run_Fuzzy_C_Means;

   ---------------------------------------------------------------------------
   -- Post-processing
   ---------------------------------------------------------------------------

   function Hard_Labels_From_Memberships
     (W : Membership_Matrix) return Hard_Labels
     with Pre => W'Length (1) >= 1
       and then W'Length (2) >= 1,
          Global => null,
          Post => Hard_Labels_From_Memberships'Result'Length = W'Length (1);
   --  Argmax_j w_ij (ties → lowest cluster index).

   function Partition_Coefficient
     (W : Membership_Matrix) return Non_Negative
     with Pre => W'Length (1) >= 1
       and then W'Length (2) >= 1,
          Global => null,
          Post => Partition_Coefficient'Result >= 0.0;
   --  PC = (1/N) Σ_i Σ_j w_ij²  ∈ [1/C, 1]; 1 = hard partition.

   function Max_Membership_Delta
     (A, B : Membership_Matrix) return Non_Negative
     with Pre => A'Length (1) = B'Length (1)
       and then A'Length (2) = B'Length (2)
       and then A'First (1) = B'First (1)
       and then A'First (2) = B'First (2),
          Global => null,
          Post => Max_Membership_Delta'Result >= 0.0;
   --  max |A_ij − B_ij| over all entries (convergence monitor).

end Fuzzy_C_Means;
