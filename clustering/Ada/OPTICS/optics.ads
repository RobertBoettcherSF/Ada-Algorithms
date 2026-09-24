--  Optics — Ada 2023 educational package for Wikipedia "OPTICS algorithm"
--  (Ordering points to identify the clustering structure). Mihael Ankerst,
--  Markus M. Breunig, Hans-Peter Kriegel, Jörg Sander, SIGMOD'99. Density-
--  based ordering with core- and reachability-distances; DBSCAN-equivalent
--  cluster extraction via a reachability threshold ξ. Handles varying
--  density better than a single DBSCAN ε. Educational reconstruction of
--  the Wikipedia / Ankerst et al. 1999 pseudocode; related: DBSCAN, SUBCLU.

pragma Ada_2022;

package Optics
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   --  Digits 12 for stable L2 / ε / reachability arithmetic.
   type Real is digits 12;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   Max_Points : constant Positive := 256;
   Max_Dims   : constant Positive := 16;

   subtype Point_Count is Natural  range 0 .. Max_Points;
   subtype Point_Id    is Positive range 1 .. Max_Points;
   subtype Dim_Count   is Natural  range 0 .. Max_Dims;
   subtype Dim_Id      is Positive range 1 .. Max_Dims;

   --  Points × dimensions. Row Point_Id, column Dim_Id.
   type Dataset is array (Point_Id range <>, Dim_Id range <>) of Real;

   --  Convenience: one coordinate vector (not required by Run_OPTICS).
   type Point is array (Dim_Id range <>) of Real;

   type Point_Id_Array is array (Point_Id range <>) of Point_Id;
   type Real_Array     is array (Point_Id range <>) of Real;
   type Bool_Array     is array (Point_Id range <>) of Boolean;

   --  Cluster label: 0 = Noise / unassigned; positive = cluster id.
   subtype Cluster_Id is Natural;
   Noise_Label : constant Cluster_Id := 0;

   type Labels is array (Point_Id range <>) of Cluster_Id;

   type Parameters is record
      Eps    : Positive_Real := 0.5;
      MinPts : Positive      := 3;
   end record;

   Default_Parameters : constant Parameters := (others => <>);

   --  Sentinel for UNDEFINED core / reachability distance.
   --  Prefer Has_* flags for queries; Undefined is a documented sentinel
   --  value stored alongside when the flag is False (never used in L2 math).
   Undefined : constant Real := -1.0;

   --  Per-point working state during / after OPTICS (educational view).
   type Optics_Point is record
      Core_Distance         : Real    := Undefined;
      Reachability_Distance : Real    := Undefined;
      Has_Core_Distance     : Boolean := False;
      Has_Reachability      : Boolean := False;
      Processed             : Boolean := False;
   end record;

   type Optics_Point_Array is array (Point_Id range <>) of Optics_Point;

   --  OPTICS output: cluster-ordering of all points with distances.
   --  Order (I) is the Point_Id written at position I in the ordering.
   --  Reachability of the first point of each seed-expansion is Undefined.
   type Ordered_Result
     (First : Point_Id;
      Last  : Natural)
   is record
      Count               : Point_Count := 0;
      Order               : Point_Id_Array (First .. Last);
      Core_Distance       : Real_Array (First .. Last);
      Reachability        : Real_Array (First .. Last);
      Has_Core_Distance   : Bool_Array (First .. Last);
      Has_Reachability    : Bool_Array (First .. Last);
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

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Make_Parameters
     (Eps : Real; MinPts : Integer) return Parameters
     with Global => null;
   --  Raises Invalid_Argument if Eps ≤ 0 or MinPts < 1.

   ---------------------------------------------------------------------------
   -- Distance / neighborhood (Euclidean L2 over all dimensions)
   ---------------------------------------------------------------------------

   function Distance
     (Data : Dataset;
      P, Q : Point_Id) return Non_Negative
     with Pre => P in Data'Range (1) and then Q in Data'Range (1),
          Global => null;
   --  Euclidean L2 distance between rows P and Q.
   --  Raises Invalid_Argument if P or Q is outside Data'Range (1).

   function Neighbor_Count
     (Data : Dataset;
      P    : Point_Id;
      Eps  : Positive_Real) return Natural
     with Pre => P in Data'Range (1),
          Global => null;
   --  |N_ε(P)| including P itself (dist(P,P)=0 ≤ Eps).

   function Core_Distance
     (Data   : Dataset;
      P      : Point_Id;
      Params : Parameters) return Real
     with Pre => P in Data'Range (1),
          Global => null;
   --  MinPts-th smallest distance in N_ε(P) (1-based; self is 0).
   --  Returns Undefined if |N_ε(P)| < MinPts.
   --  Raises Invalid_Argument if P out of range or Params invalid.

   function Is_Core_Point
     (Data   : Dataset;
      P      : Point_Id;
      Params : Parameters) return Boolean
     with Pre => P in Data'Range (1),
          Global => null;
   --  True iff |N_ε(P)| ≥ MinPts.

   function Has_Defined_Core
     (Data   : Dataset;
      P      : Point_Id;
      Params : Parameters) return Boolean
     with Pre => P in Data'Range (1),
          Global => null;
   --  Alias of Is_Core_Point (core-distance ≠ UNDEFINED).

   ---------------------------------------------------------------------------
   -- OPTICS ordering
   ---------------------------------------------------------------------------

   function Run_OPTICS
     (Data   : Dataset;
      Params : Parameters) return Ordered_Result
     with Pre => Data'Length (1) >= 1 and then Data'Length (2) >= 1,
          Global => null;
   --  OPTICS(DB, ε, MinPts): produce the cluster-ordering with per-point
   --  core- and reachability-distances (Undefined where applicable).
   --  Raises Invalid_Argument for empty DB, Eps≤0, MinPts<1, or dims=0.
   --  Raises Capacity_Exceeded if Data'Length (1) > Max_Points or
   --  Data'Length (2) > Max_Dims.

   ---------------------------------------------------------------------------
   -- Cluster extraction (ξ / reachability threshold — DBSCAN-equivalent)
   ---------------------------------------------------------------------------
   --
   --  Extraction rule (Ankerst et al. / Wikipedia threshold cut):
   --    Walk the OPTICS order. Maintain ClusterId (initially Noise).
   --    For each point O in order:
   --      if reachability(O) is Undefined OR reachability(O) > ξ then
   --        if core-distance(O) is defined AND core-distance(O) ≤ ξ then
   --          start a new cluster; assign O to it
   --        else
   --          assign O as Noise
   --      else  -- reachability(O) ≤ ξ
   --        assign O to the current ClusterId
   --          (may still be Noise if no cluster has started yet)
   --    Require ξ ≤ Params.Eps used to build the ordering (enforced).
   --    First point in order has Undefined reachability; it starts a
   --    cluster iff it is a core point w.r.t. ξ (core-dist ≤ ξ).
   --    Noise = points that never join a dense valley under threshold ξ.
   ---------------------------------------------------------------------------

   function Extract_DBSCAN_Clustering
     (Ordered : Ordered_Result;
      Xi      : Positive_Real) return Labels
     with Global => null;
   --  DBSCAN-equivalent labels from a reachability threshold ξ.
   --  Raises Invalid_Argument if Ordered is empty or Xi ≤ 0.

   function Labels_At_Xi
     (Ordered : Ordered_Result;
      Xi      : Positive_Real) return Labels
     with Global => null;
   --  Synonym of Extract_DBSCAN_Clustering.

   function Cluster_Count_Of (Lab : Labels) return Natural
     with Global => null;
   --  Number of distinct positive cluster ids present in Lab.

   function Noise_Count_Of (Lab : Labels) return Natural
     with Global => null;

end Optics;
