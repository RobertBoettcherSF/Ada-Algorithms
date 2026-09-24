--  Flame_Clustering — Ada 2023 educational package for Wikipedia
--  "FLAME clustering": Fuzzy clustering by Local Approximation of
--  MEmberships (Fu & Medico, BMC Bioinformatics 2007).  Clusters form
--  around dense Cluster Supporting Objects (CSOs); memberships of type-3
--  objects are diffused from KNN via Neighborhood Approximation Error
--  (NAE) minimization.  Self-contained sibling of Ada-Fuzzy-C-Means.

pragma Ada_2022;

package Flame_Clustering
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   --  Digits 12 for stable density / membership arithmetic.
   type Real is digits 12;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Unit_Interval is Real range 0.0 .. 1.0;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   Max_Points      : constant Positive := 256;
   Max_Dims        : constant Positive := 16;
   Max_K_Neighbors : constant Positive := 32;
   --  Max CSOs (cluster peaks).  Membership columns = Num_CSOs + 1 (outlier).
   Max_Clusters    : constant Positive := 32;

   subtype Point_Count   is Natural  range 0 .. Max_Points;
   subtype Point_Index   is Positive range 1 .. Max_Points;
   subtype Dim_Count     is Natural  range 0 .. Max_Dims;
   subtype Dim_Index     is Positive range 1 .. Max_Dims;
   subtype Neighbor_Count is Natural range 0 .. Max_K_Neighbors;
   subtype Neighbor_Index is Positive range 1 .. Max_K_Neighbors;
   --  Membership / label columns: CSOs + outlier group (≤ Max_Clusters + 1).
   subtype Cluster_Count is Natural  range 0 .. Max_Clusters + 1;
   subtype Cluster_Index is Positive range 1 .. Max_Clusters + 1;

   --  Coordinate vector of one observation.
   type Point is array (Dim_Index range <>) of Real;

   --  Data(P, D) = coordinate D of point P.  Rows = observations.
   type Dataset is array
     (Point_Index range <>, Dim_Index range <>) of Real;

   type Densities is array (Point_Index range <>) of Real;

   type Object_Kind is (CSO, Outlier, Rest);

   type Kind_Array is array (Point_Index range <>) of Object_Kind;

   --  KNN neighbor ids and distances for one object (1 .. K used).
   type Neighbor_Ids is array (Neighbor_Index range <>) of Point_Index;
   type Neighbor_Dists is array (Neighbor_Index range <>) of Non_Negative;

   type KNN_Row is record
      Count : Neighbor_Count := 0;
      Ids   : Neighbor_Ids (1 .. Max_K_Neighbors) := [others => 1];
      Dists : Neighbor_Dists (1 .. Max_K_Neighbors) := [others => 0.0];
   end record;

   type KNN_Graph is array (Point_Index range <>) of KNN_Row;

   --  Membership_Matrix(I, J) = p_J(x_I); rows should sum ≈ 1.
   --  Columns 1 .. Num_CSOs = CSO clusters; last = outlier group when used.
   type Membership_Matrix is array
     (Point_Index range <>, Cluster_Index range <>) of Real;

   --  Hard label per point: cluster column index (1 .. M); 0 = unset.
   type Labels is array (Point_Index range <>) of Natural;

   --  Soft one-to-multiple: True iff membership > Threshold.
   type Assignment_Matrix is array
     (Point_Index range <>, Cluster_Index range <>) of Boolean;

   --  Maps CSO cluster column → supporting object index (1 .. Num_CSOs).
   type CSO_List is array (Cluster_Index range <>) of Point_Index;

   type Parameters is record
      K                 : Neighbor_Count := 3;
      Outlier_Threshold : Non_Negative := 0.05;
      Max_Iters         : Positive := 200;
      Eps               : Non_Negative := 1.0E-6;
      Assign_Threshold  : Unit_Interval := 0.5;
   end record;

   Default_Parameters : constant Parameters := (others => <>);

   type Flame_Result
     (N : Point_Count; M : Cluster_Count)
   is record
      Densities     : Flame_Clustering.Densities (1 .. N);
      Kinds         : Kind_Array (1 .. N);
      Graph         : KNN_Graph (1 .. N);
      Memberships   : Membership_Matrix (1 .. N, 1 .. M);
      Num_CSOs      : Cluster_Count := 0;
      CSO_Of        : CSO_List (1 .. Max_Clusters) := [others => 1];
      Hard_Labels   : Labels (1 .. N) := [others => 0];
      Iters         : Natural := 0;
      Converged     : Boolean := False;
      Final_NAE     : Non_Negative := 0.0;
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument  : exception;
   Capacity_Exceeded : exception;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-8;
   --  Floor added to distances in density / inverse-distance weights.
   Distance_Eps : constant Real := 1.0E-12;

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

   function Extract_Point
     (Data : Dataset; P : Point_Index) return Point
     with Pre => P in Data'Range (1)
       and then Data'Length (2) >= 1
       and then Data'Length (2) <= Max_Dims,
          Global => null,
          Post => Extract_Point'Result'Length = Data'Length (2);

   ---------------------------------------------------------------------------
   -- Step 1: structure extraction
   ---------------------------------------------------------------------------

   function Build_KNN
     (Data : Dataset; K : Neighbor_Count) return KNN_Graph
     with Pre => Data'Length (1) >= 1
       and then Data'Length (1) <= Max_Points
       and then Data'Length (2) >= 1
       and then Data'Length (2) <= Max_Dims
       and then K >= 1
       and then K <= Max_K_Neighbors
       and then Natural (K) < Data'Length (1),
          Global => null,
          Post => Build_KNN'Result'Length = Data'Length (1);
   --  Each object → its K nearest others (Euclidean).  Distance ties:
   --  prefer lower Point_Index (stable).  Raises Invalid_Argument if K < 1
   --  or K ≥ N; Capacity_Exceeded if caps exceeded.

   function Estimate_Densities
     (Graph : KNN_Graph) return Densities
     with Pre => Graph'Length >= 1
       and then Graph'Length <= Max_Points,
          Global => null,
          Post => Estimate_Densities'Result'Length = Graph'Length;
   --  density(x) = 1 / mean_distance(x, KNN(x)), using Distance_Eps floor
   --  when the mean is ~0 (coincident neighbors).  Higher ⇒ denser.

   function Classify_Objects
     (Dens   : Densities;
      Graph  : KNN_Graph;
      Out_Th : Non_Negative) return Kind_Array
     with Pre => Dens'Length = Graph'Length
       and then Dens'First = Graph'First
       and then Dens'Last = Graph'Last
       and then Dens'Length >= 1,
          Global => null,
          Post => Classify_Objects'Result'Length = Dens'Length;
   --  CSO: density strictly > all K neighbors.
   --  Outlier: density strictly < all K neighbors AND density < Out_Th.
   --  Rest: otherwise.  Equal densities never make a CSO/outlier vs that nbr.

   ---------------------------------------------------------------------------
   -- Step 2: local approximation of fuzzy memberships
   ---------------------------------------------------------------------------

   procedure Init_Memberships
     (Kinds  : Kind_Array;
      Graph  : KNN_Graph;
      W      : out Membership_Matrix;
      Num_CSOs : out Cluster_Count;
      CSO_Of : out CSO_List)
     with Pre => Kinds'Length = Graph'Length
       and then Kinds'First = Graph'First
       and then W'Length (1) = Kinds'Length
       and then W'First (1) = Kinds'First
       and then W'Length (2) >= 1
       and then CSO_Of'First = 1
       and then CSO_Of'Last >= Max_Clusters,
          Global => null;
   --  M = (#CSOs)+1.  Requires W'Length(2) ≥ M (caller sizes after counting
   --  or uses Max_Clusters+1).  Each CSO fixed membership 1 to own cluster;
   --  outliers fixed 1 to outlier group; type-3 equal 1/M to all columns.
   --  Raises Invalid_Argument if #CSOs > Max_Clusters or M > W'Length(2);
   --  Capacity_Exceeded if too many CSOs for Max_Clusters.

   function Neighborhood_Weights
     (Row : KNN_Row) return Neighbor_Dists
     with Pre => Row.Count >= 1,
          Global => null;
   --  Inverse-distance weights over KNN: w_i ∝ 1/(d_i + Distance_Eps),
   --  normalized so Σ w = 1.  Returned in 1 .. Row.Count (rest unused).

   function Neighborhood_Approximation_Error
     (Kinds : Kind_Array;
      Graph : KNN_Graph;
      W     : Membership_Matrix) return Non_Negative
     with Pre => Kinds'Length = Graph'Length
       and then Kinds'First = Graph'First
       and then W'Length (1) = Kinds'Length
       and then W'First (1) = Kinds'First
       and then W'Length (2) >= 1,
          Global => null,
          Post => Neighborhood_Approximation_Error'Result >= 0.0;
   --  NAE = Σ_{x type-3} || p(x) − Σ_{y∈N(x)} w_xy p(y) ||².

   procedure Approximate_Memberships
     (Kinds     : Kind_Array;
      Graph     : KNN_Graph;
      W         : in out Membership_Matrix;
      Max_Iters : Positive;
      Eps       : Non_Negative;
      Iters     : out Natural;
      Converged : out Boolean;
      Final_NAE : out Non_Negative)
     with Pre => Kinds'Length = Graph'Length
       and then Kinds'First = Graph'First
       and then W'Length (1) = Kinds'Length
       and then W'First (1) = Kinds'First
       and then W'Length (2) >= 1
       and then Eps >= 0.0,
          Global => null;
   --  Iterate p^{t+1}(x) = Σ w_xy p^t(y) for type-3 only until max |Δp| < Eps
   --  or Max_Iters.  CSOs/outliers stay fixed.  Jacobi-style (uses previous
   --  iteration snapshot for all updates).

   ---------------------------------------------------------------------------
   -- Step 3: cluster construction / full driver
   ---------------------------------------------------------------------------

   function Hard_Labels_From_Memberships
     (W : Membership_Matrix) return Labels
     with Pre => W'Length (1) >= 1
       and then W'Length (2) >= 1,
          Global => null,
          Post => Hard_Labels_From_Memberships'Result'Length = W'Length (1);
   --  Argmax_j membership (ties → lowest cluster index). One-to-one.

   function Threshold_Assign
     (W         : Membership_Matrix;
      Threshold : Unit_Interval) return Assignment_Matrix
     with Pre => W'Length (1) >= 1
       and then W'Length (2) >= 1
       and then Threshold >= 0.0
       and then Threshold <= 1.0,
          Global => null,
          Post => Threshold_Assign'Result'Length (1) = W'Length (1)
            and then Threshold_Assign'Result'Length (2) = W'Length (2);
   --  One-to-multiple: assign to every cluster with membership > Threshold.

   function Run_FLAME
     (Data   : Dataset;
      Params : Parameters := Default_Parameters) return Flame_Result
     with Pre => Data'Length (1) >= 2
       and then Data'Length (1) <= Max_Points
       and then Data'Length (2) >= 1
       and then Data'Length (2) <= Max_Dims
       and then Params.K >= 1
       and then Params.K <= Max_K_Neighbors
       and then Natural (Params.K) < Data'Length (1)
       and then Params.Eps >= 0.0,
          Global => null;
   --  Full pipeline: Build_KNN → Estimate_Densities → Classify_Objects →
   --  Init_Memberships → Approximate_Memberships → Hard_Labels.
   --  Raises Invalid_Argument for bad K / empty CSOs edge cases handled
   --  gracefully (M=1 outlier-only if no CSOs); Capacity_Exceeded on caps.

   function Count_CSOs (Kinds : Kind_Array) return Cluster_Count
     with Global => null;

   function Max_Membership_Delta
     (A, B : Membership_Matrix) return Non_Negative
     with Pre => A'Length (1) = B'Length (1)
       and then A'Length (2) = B'Length (2)
       and then A'First (1) = B'First (1)
       and then A'First (2) = B'First (2),
          Global => null,
          Post => Max_Membership_Delta'Result >= 0.0;

end Flame_Clustering;
