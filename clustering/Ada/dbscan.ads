--  DBSCAN — Ada 2023 educational package for Wikipedia "DBSCAN"
--  (Density-Based Spatial Clustering of Applications with Noise).
--  Martin Ester, Hans-Peter Kriegel, Jörg Sander, Xiaowei Xu,
--  KDD'96. Density-based clustering with parameters Eps (ε) and MinPts:
--  core / border / noise points; arbitrarily shaped clusters; noise
--  rejection. Educational reconstruction of the Wikipedia / Ester et al.
--  original query-based algorithm (linear RangeQuery). Related (README):
--  OPTICS, SUBCLU.

pragma Ada_2022;

package DBSCAN
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   --  Digits 12 for stable L2 / ε arithmetic.
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

   --  Convenience: one coordinate vector (not required by Run_DBSCAN).
   type Point is array (Dim_Id range <>) of Real;

   type Point_Id_Array is array (Point_Id range <>) of Point_Id;

   --  Cluster labels: Undefined sentinel, Noise, then positive cluster ids.
   --  Integer so Undefined can be negative while Noise is 0.
   subtype Cluster_Label is Integer;
   Undefined_Label : constant Cluster_Label := -1;
   Noise_Label     : constant Cluster_Label := 0;

   type Labels is array (Point_Id range <>) of Cluster_Label;

   --  Optional classification of each point after a run.
   type Point_Kind is (Undefined_Kind, Noise_Kind, Core_Kind, Border_Kind);
   type Point_Kind_Array is array (Point_Id range <>) of Point_Kind;

   type Parameters is record
      Eps    : Positive_Real := 0.5;
      MinPts : Positive      := 4;
   end record;

   Default_Parameters : constant Parameters := (others => <>);

   --  Full DBSCAN outcome (discriminants fix label storage extents).
   type Result
     (First : Point_Id;
      Last  : Natural)
   is record
      Lab           : Labels (First .. Last);
      Kind          : Point_Kind_Array (First .. Last);
      Cluster_Count : Natural := 0;
      Noise_Count   : Natural := 0;
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

   function Range_Query
     (Data : Dataset;
      P    : Point_Id;
      Eps  : Positive_Real) return Point_Id_Array
     with Pre => P in Data'Range (1),
          Global => null;
   --  N_ε(P): all points Q with dist(P,Q) ≤ Eps, including P.
   --  Result length = |N_ε(P)|; indices are 1 .. Length (dense pack).
   --  Linear scan (Wikipedia educational RangeQuery).

   function Neighbor_Count
     (Data : Dataset;
      P    : Point_Id;
      Eps  : Positive_Real) return Natural
     with Pre => P in Data'Range (1),
          Global => null;
   --  |N_ε(P)| including P itself (dist(P,P)=0 ≤ Eps).

   function Is_Core_Point
     (Data   : Dataset;
      P      : Point_Id;
      Params : Parameters) return Boolean
     with Pre => P in Data'Range (1),
          Global => null;
   --  True iff |N_ε(P)| ≥ MinPts (MinPts includes self).

   ---------------------------------------------------------------------------
   -- DBSCAN (Ester et al. / Wikipedia query-based algorithm)
   ---------------------------------------------------------------------------

   function Run_DBSCAN
     (Data   : Dataset;
      Params : Parameters) return Result
     with Pre => Data'Length (1) >= 1 and then Data'Length (2) >= 1,
          Global => null;
   --  DBSCAN(DB, eps, minPts): label every point as Noise or a positive
   --  cluster id; classify Core / Border / Noise kinds.
   --  Raises Invalid_Argument for empty DB, Eps≤0, MinPts<1, or dims=0.
   --  Raises Capacity_Exceeded if Data'Length (1) > Max_Points or
   --  Data'Length (2) > Max_Dims.

   function Cluster_Count_Of (Lab : Labels) return Natural
     with Global => null;
   --  Number of distinct positive cluster ids present in Lab.

   function Noise_Count_Of (Lab : Labels) return Natural
     with Global => null;
   --  Count of Lab (I) = Noise_Label (Undefined not counted as noise).

end DBSCAN;
