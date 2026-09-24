--  Subclu — Ada 2023 educational package for Wikipedia "SUBCLU"
--  (density-connected subspace clustering). Karin Kailing, Hans-Peter
--  Kriegel, Peer Kröger, SDM'04: Density-Connected Subspace Clustering
--  for High-Dimensional Data. Axis-parallel, bottom-up Apriori-style
--  search over subspaces, with DBSCAN as the density-connected cluster
--  finder in each candidate subspace. Educational reconstruction of the
--  Wikipedia / SDM'04 pseudocode; related: DBSCAN, CLIQUE, PreDeCon.

pragma Ada_2022;

package Subclu
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   --  Digits 12 for stable L2 / ε arithmetic.
   type Real is digits 12;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   Max_Points    : constant Positive := 128;
   Max_Dims      : constant Positive := 12;
   Max_Subspaces : constant Positive := 64;
   Max_Clusters  : constant Positive := 96;

   subtype Point_Count is Natural  range 0 .. Max_Points;
   subtype Point_Id    is Positive range 1 .. Max_Points;
   subtype Dim_Count   is Natural  range 0 .. Max_Dims;
   subtype Dim_Id      is Positive range 1 .. Max_Dims;
   subtype Subspace_Count is Natural range 0 .. Max_Subspaces;
   subtype Cluster_Count  is Natural range 0 .. Max_Clusters;

   --  Points × dimensions. Row Point_Id, column Dim_Id.
   type Dataset is array (Point_Id range <>, Dim_Id range <>) of Real;

   --  Sorted unique attribute indices (axis-parallel subspace).
   type Attr_Array is array (1 .. Max_Dims) of Dim_Id;
   type Dim_Id_Array is array (Positive range <>) of Dim_Id;

   type Subspace is record
      Count : Dim_Count := 0;
      Attrs : Attr_Array := [others => 1];
   end record;

   type Subspace_List is array (1 .. Max_Subspaces) of Subspace;

   --  Active point subset for restricted DBSCAN (full DB or a lower cluster).
   type Point_Id_Array is array (1 .. Max_Points) of Point_Id;

   type Point_Subset is record
      Count : Point_Count := 0;
      Ids   : Point_Id_Array := [others => 1];
   end record;

   --  Cluster label: 0 = Noise / unassigned; positive = cluster id.
   subtype Cluster_Id is Natural;
   Noise_Label : constant Cluster_Id := 0;

   type Label_Array is array (Point_Id range <>) of Cluster_Id;

   type Parameters is record
      Eps    : Positive_Real := 0.5;
      MinPts : Positive      := 3;
   end record;

   Default_Parameters : constant Parameters := (others => <>);

   --  One density-connected cluster in a concrete subspace.
   type Cluster_Info is record
      Space   : Subspace;
      Label   : Cluster_Id := 0;
      Size    : Point_Count := 0;
      Members : Point_Id_Array := [others => 1];
   end record;

   type Cluster_Info_Array is array (1 .. Max_Clusters) of Cluster_Info;

   --  Full SUBCLU output: every non-empty subspace cluster found.
   type SUBCLU_Result is record
      Cluster_Count  : Natural range 0 .. Max_Clusters := 0;
      Clusters       : Cluster_Info_Array;
      Subspace_Count : Natural range 0 .. Max_Subspaces := 0;
      Subspaces      : Subspace_List;
   end record;

   --  Result of a single DBSCAN run over a point subset + subspace.
   type DBSCAN_Result
     (First : Point_Id;
      Last  : Natural)
   is record
      Labels        : Label_Array (First .. Last);
      Cluster_Count : Natural range 0 .. Max_Clusters := 0;
      Noise_Count   : Point_Count := 0;
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument  : exception;
   Capacity_Exceeded : exception;

   ---------------------------------------------------------------------------
   -- Numeric / subspace helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-8;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Empty_Subspace return Subspace
     with Global => null, Inline;

   function Make_Subspace (Attrs : Dim_Id_Array) return Subspace
     with Global => null;
   --  Build a sorted unique subspace from an attribute list.
   --  Duplicates are dropped; empty Attrs yields empty subspace.

   function Subspace_Contains
     (S : Subspace; A : Dim_Id) return Boolean
     with Global => null;

   function Subspace_Equal (A, B : Subspace) return Boolean
     with Global => null;

   function Subspace_Subset (A, B : Subspace) return Boolean
     with Global => null;
   --  True iff every attribute of A is in B (A ⊆ B).

   function Subspace_Union (A, B : Subspace) return Subspace
     with Global => null;
   --  Raises Capacity_Exceeded if |A ∪ B| > Max_Dims.

   function Subspace_Intersection (A, B : Subspace) return Subspace
     with Global => null;

   function Differ_By_One (A, B : Subspace) return Boolean
     with Global => null;
   --  True iff |A| = |B| = k ≥ 1, |A ∩ B| = k−1, |A ∪ B| = k+1.

   function Dim_In_Range
     (Data : Dataset; A : Dim_Id) return Boolean
     with Global => null, Inline;

   ---------------------------------------------------------------------------
   -- Distance / neighborhood (L2 on selected dimensions only)
   ---------------------------------------------------------------------------

   function Distance
     (Data  : Dataset;
      P, Q  : Point_Id;
      Space : Subspace) return Non_Negative
     with Pre => P in Data'Range (1) and then Q in Data'Range (1),
          Global => null;
   --  Euclidean distance using only attributes in Space.
   --  Raises Invalid_Argument if P/Q out of range, Space empty, or an
   --  attribute is outside Data'Range (2).

   function Neighborhood_Count
     (Data   : Dataset;
      P      : Point_Id;
      Space  : Subspace;
      Eps    : Positive_Real;
      Active : Point_Subset) return Natural
     with Pre => P in Data'Range (1),
          Global => null;
   --  |{ q ∈ Active : dist_Space(P,q) ≤ Eps }| (includes P when in Active).

   function Is_Core_Point
     (Data   : Dataset;
      P      : Point_Id;
      Space  : Subspace;
      Params : Parameters;
      Active : Point_Subset) return Boolean
     with Pre => P in Data'Range (1),
          Global => null;

   function Full_Point_Subset (N : Point_Count) return Point_Subset
     with Pre => N <= Max_Points, Global => null;
   --  {1, 2, …, N}.

   function Make_Parameters
     (Eps : Real; MinPts : Integer) return Parameters
     with Global => null;
   --  Raises Invalid_Argument if Eps ≤ 0 or MinPts < 1.

   ---------------------------------------------------------------------------
   -- DBSCAN in a subspace (restricted to Active points)
   ---------------------------------------------------------------------------

   function DBSCAN
     (Data   : Dataset;
      Space  : Subspace;
      Params : Parameters;
      Active : Point_Subset) return DBSCAN_Result
     with Pre => Data'Length (1) >= 1 and then Data'Length (2) >= 1,
          Global => null;
   --  Classic DBSCAN with L2 restricted to Space, only among Active.
   --  Labels indexed by Data'Range (1); points not in Active stay Noise.
   --  Raises Invalid_Argument for empty Data, empty Space, bad Params,
   --  Active ids out of range, or attributes outside Data dims.
   --  Raises Capacity_Exceeded if more than Max_Clusters clusters form.

   ---------------------------------------------------------------------------
   -- Candidate generation (Apriori-style)
   ---------------------------------------------------------------------------

   procedure Generate_Candidate_Subspaces
     (Sk         : Subspace_List;
      Sk_Count   : Subspace_Count;
      Cand       : out Subspace_List;
      Cand_Count : out Subspace_Count)
     with Global => null;
   --  Pairwise combine k-dim subspaces that differ in exactly one
   --  attribute into (k+1)-dim candidates; prune any candidate that has
   --  a k-subset absent from Sk.  Raises Invalid_Argument if Sk_Count
   --  entries are not all the same dimensionality (when Sk_Count ≥ 1).
   --  Raises Capacity_Exceeded if too many candidates.

   ---------------------------------------------------------------------------
   -- Full SUBCLU
   ---------------------------------------------------------------------------

   function Run_SUBCLU
     (Data   : Dataset;
      Params : Parameters) return SUBCLU_Result
     with Pre => Data'Length (1) >= 1 and then Data'Length (2) >= 1,
          Global => null;
   --  Bottom-up density-connected subspace clustering.
   --  Raises Invalid_Argument for empty DB, Eps≤0, MinPts<1.
   --  Raises Capacity_Exceeded if Max_Subspaces / Max_Clusters overflow.

   function Clustered_In_Subspace
     (Result : SUBCLU_Result;
      Space  : Subspace;
      P      : Point_Id) return Boolean
     with Global => null;
   --  True if some reported cluster in exactly Space contains P.

   function Total_Clustered_Points
     (Result : SUBCLU_Result;
      Space  : Subspace) return Point_Count
     with Global => null;
   --  Sum of sizes of clusters whose Space equals the given subspace
   --  (clusters in one subspace are disjoint).

end Subclu;
